#include "occt_viewer.h"
#include "viewer_state.h"
#include "viewer_window.h"
#include "viewer_widget.h"
#include "repl_panel.h"
#include "scene_tree_panel.h"
#include "OcctQtTools.h"
#include "icon_data.h"

#include <AIS_Trihedron.hxx>
#include <AIS_ViewCube.hxx>
#include <V3d_TypeOfOrientation.hxx>
#include <Geom_Axis2Placement.hxx>
#include <Graphic3d_TransformPers.hxx>
#include <Graphic3d_TransModeFlags.hxx>
#include <Aspect_TypeOfTriedronPosition.hxx>
#include <Prs3d_DatumMode.hxx>
#include <Prs3d_DatumAspect.hxx>
#include <Prs3d_DatumParts.hxx>
#include <gp.hxx>
#include <TopoDS_Shape.hxx>
#include <V3d_View.hxx>
#include <Standard_Version.hxx>


#include <Standard_WarningsDisable.hxx>
#include <QApplication>
#include <QPixmap>
#include <QIcon>
#include <QObject>
#include <QEvent>
#include <QCoreApplication>
#include <QFileDialog>
#include <QMessageBox>
#include <QPushButton>
#include <QDialog>
#include <QVBoxLayout>
#include <QLabel>
#include <QDialogButtonBox>
#include <QStyleHints>
#include <QTimer>
#include <QDockWidget>
#include <QStyleHints>
#include <QProxyStyle>
#include <QPainter>
#include <QStyleOptionToolButton>
#include <QToolButton>
#include <map>
#include <string>
#include <vector>
#include <cstring>
#include <algorithm>
#include <set>
#include <Standard_WarningsRestore.hxx>

static const QEvent::Type WakeEventType = static_cast<QEvent::Type>(QEvent::User + 1);

// ---------------------------------------------------------------------------
//  Proxy style that generates theme-aware standard icons.
//  Required because QFileDialog's parent-directory toolbar button uses
//  QIcon::fromTheme("go-up") or standardIcon(SP_FileDialogToParent), both of
//  which return a black system-theme icon on Linux.  We intercept
//  SP_FileDialogToParent and paint an arrow using QPalette::ButtonText so it
//  always matches the current light/dark foreground color.
// ---------------------------------------------------------------------------
class ThemeIconStyle : public QProxyStyle
{
public:
  using QProxyStyle::QProxyStyle;

  QIcon standardIcon(StandardPixmap pixmap, const QStyleOption* option, const QWidget* widget) const override
  {
    if (pixmap == SP_FileDialogToParent || pixmap == SP_ArrowBack || pixmap == SP_ArrowForward)
    {
      QColor fg = QColor("#e0e0e0");
      if (option)
        fg = option->palette.color(QPalette::ButtonText);
      else if (widget)
        fg = widget->palette().color(QPalette::ButtonText);
      else
        fg = QApplication::palette().color(QPalette::ButtonText);

      QPixmap pm(20, 20);
      pm.fill(Qt::transparent);
      QPainter p(&pm);
      p.setRenderHint(QPainter::Antialiasing);
      p.translate(10, 10);
      if (pixmap == SP_ArrowBack)
        p.rotate(-90);
      else if (pixmap == SP_ArrowForward)
        p.rotate(90);
      QFont f = p.font();
      f.setPixelSize(18);
      f.setBold(true);
      p.setFont(f);
      p.setPen(fg);
      p.drawText(QRect(-10, -10, 20, 20), Qt::AlignCenter, QStringLiteral("\u25B2"));
      p.end();

      return QIcon(pm);
    }
    return QProxyStyle::standardIcon(pixmap, option, widget);
  }
};

// Map a direction vector (Vx, Vy, Vz) to the closest V3d_TypeOfOrientation.
// Uses the Y-up convention matching our application (V3d_TypeOfOrientation_Yup_* aliases).
static V3d_TypeOfOrientation directionToOrientation(double Vx, double Vy, double Vz)
{
  // Normalize
  double len = sqrt(Vx * Vx + Vy * Vy + Vz * Vz);
  if (len < 1e-10) return V3d_XposYposZpos;
  Vx /= len; Vy /= len; Vz /= len;

  // Find closest standard direction
  struct Dir { double x, y, z; V3d_TypeOfOrientation orient; };
  static const Dir dirs[] = {
    { 1, 0, 0, V3d_Xpos }, { -1, 0, 0, V3d_Xneg },
    { 0, 1, 0, V3d_Ypos }, { 0, -1, 0, V3d_Yneg },
    { 0, 0, 1, V3d_Zpos }, { 0, 0, -1, V3d_Zneg },
    { 1, 1, 1, V3d_XposYposZpos }, { 1, 1, -1, V3d_XposYposZneg },
    { 1, -1, 1, V3d_XposYnegZpos }, { 1, -1, -1, V3d_XposYnegZneg },
    { -1, 1, 1, V3d_XnegYposZpos }, { -1, 1, -1, V3d_XnegYposZneg },
    { -1, -1, 1, V3d_XnegYnegZpos }, { -1, -1, -1, V3d_XnegYnegZneg },
  };
  int best = 0;
  double bestDot = -2.0;
  for (int i = 0; i < 14; i++)
  {
    double d = dirs[i].x * Vx + dirs[i].y * Vy + dirs[i].z * Vz;
    double n = sqrt(dirs[i].x * dirs[i].x + dirs[i].y * dirs[i].y + dirs[i].z * dirs[i].z);
    double dot = d / n;
    if (dot > bestDot) { bestDot = dot; best = i; }
  }
  return dirs[best].orient;
}

class ViewCubeWithCallback : public AIS_ViewCube
{
public:
  ViewCubeWithCallback(ViewerState* s) : AIS_ViewCube(), myState(s) {}
protected:
  void onAnimationFinished() override
  {
    if (myState && myState->viewcube_callback && myState->widget && !myState->widget->View().IsNull())
    {
      double Vx, Vy, Vz;
      myState->widget->View()->Proj(Vx, Vy, Vz);
      V3d_TypeOfOrientation orient = directionToOrientation(Vx, Vy, Vz);
      myState->currentOrientation = static_cast<int>(orient);
      myState->viewcube_callback(myState->currentOrientation);
    }
  }
private:
  ViewerState* myState = nullptr;
};

class WakeEvent : public QEvent
{
public:
  WakeEvent() : QEvent(WakeEventType) {}
};

static QApplication* theApp = nullptr;
static int theArgc = 1;
static const char* theArgv[] = {"ClotCAD", nullptr};

static void ensureQApplication()
{
  if (!theApp)
  {
    qputenv("QT_QPA_PLATFORM", "xcb");
    OcctQtTools::qtGlPlatformSetup();
    theApp = new QApplication(theArgc, const_cast<char**>(theArgv));
    theApp->setStyle(new ThemeIconStyle(theApp->style()));
    QPixmap pm;
    if (pm.loadFromData(clotcad_icon_png, clotcad_icon_png_len))
      theApp->setWindowIcon(QIcon(pm));
  }
}

class WakeReceiver : public QObject
{
public:
  ViewerState* state;
  WakeReceiver(ViewerState* s) : QObject(), state(s) {}
  bool eventFilter(QObject* watched, QEvent* e) override
  {
    if (e->type() == WakeEventType)
    {
      if (state->drain_callback)
        state->drain_callback();
      if (state->widget)
        state->widget->update();
      return true;
    }
    return QObject::eventFilter(watched, e);
  }
};

static void showAboutDialog(QWidget* parent)
{
  QDialog dlg(parent);
  dlg.setWindowTitle(QStringLiteral("About ClotCAD"));
  dlg.setFixedSize(420, 380);

  auto* layout = new QVBoxLayout(&dlg);
  layout->setAlignment(Qt::AlignCenter);
  layout->setSpacing(8);
  layout->setContentsMargins(24, 24, 24, 16);

  auto* logoLabel = new QLabel(&dlg);
  QPixmap logo(QStringLiteral(":/icons/ClotCAD-logo.svg"));
  if (!logo.isNull())
    logoLabel->setPixmap(logo.scaledToWidth(80, Qt::SmoothTransformation));
  logoLabel->setAlignment(Qt::AlignCenter);
  layout->addWidget(logoLabel);

  auto* nameLabel = new QLabel(
    QStringLiteral("<h2>ClotCAD %1</h2>").arg(CLOTCAD_VERSION), &dlg);
  nameLabel->setAlignment(Qt::AlignCenter);
  layout->addWidget(nameLabel);

  auto* versLabel = new QLabel(
    QStringLiteral("OCCT %1 | Qt %2 | %3")
      .arg(OCC_VERSION_COMPLETE)
      .arg(QT_VERSION_STR)
      .arg(SBCL_VERSION),
    &dlg);
  versLabel->setAlignment(Qt::AlignCenter);
  versLabel->setStyleSheet("QLabel { color: gray; font-size: 11px; }");
  layout->addWidget(versLabel);

  auto* descLabel = new QLabel(
    QStringLiteral(
      "<p>A parametric CAD application built on "
      "OpenCASCADE Technology and Qt.</p>"),
    &dlg);
  descLabel->setAlignment(Qt::AlignCenter);
  descLabel->setWordWrap(true);
  layout->addWidget(descLabel);

  auto* linksLabel = new QLabel(
    QStringLiteral(
      "<p style='line-height: 1.6;'>"
      "<a href='https://github.com/torusJKL/ClotCAD' style='color: %1;'>ClotCAD</a><br>"
      "<a href='https://dev.opencascade.org/' style='color: %2;'>OCCT</a><br>"
      "<a href='https://www.qt.io/' style='color: %3;'>Qt</a><br>"
      "<a href='https://www.sbcl.org/' style='color: %4;'>SBCL</a>"
      "</p>")
      .arg(dlg.palette().color(QPalette::Link).name())
      .arg(dlg.palette().color(QPalette::Link).name())
      .arg(dlg.palette().color(QPalette::Link).name())
      .arg(dlg.palette().color(QPalette::Link).name()),
    &dlg);
  linksLabel->setAlignment(Qt::AlignCenter);
  linksLabel->setOpenExternalLinks(true);
  layout->addWidget(linksLabel);

  layout->addStretch();

  auto* buttonBox = new QDialogButtonBox(QDialogButtonBox::Close, &dlg);
  QObject::connect(buttonBox, &QDialogButtonBox::rejected, &dlg, &QDialog::reject);
  layout->addWidget(buttonBox);

  dlg.exec();
}

// ========== C API ==========

occt_viewer viewer_create(const char* title, int width, int height)
{
  ensureQApplication();
  auto* s = new ViewerState();
  auto* win = new ViewerWindow(title, width, height);
  {
    QPixmap pm;
    if (pm.loadFromData(clotcad_icon_png, clotcad_icon_png_len))
      win->setWindowIcon(QIcon(pm));
  }
  s->window = win;
  s->widget = win->viewport();
  s->widget->setViewerState(s);
  s->context = win->viewport()->Context();

  // Wire File menu actions
  QObject::connect(win->importStepAction(), &QAction::triggered, [s]() {
    if (!s->file_op_callback) return;
    QFileDialog dialog(s->window, "Import STEP", QString(), "STEP Files (*.step *.STEP)");
    dialog.setFileMode(QFileDialog::ExistingFile);
    dialog.setAcceptMode(QFileDialog::AcceptOpen);
    dialog.setOption(QFileDialog::DontUseNativeDialog);
    if (dialog.exec() == QDialog::Accepted)
    {
      QString path = dialog.selectedFiles().value(0);
      if (!path.isEmpty())
        s->file_op_callback(path.toUtf8().constData(), 0);
    }
  });

  QObject::connect(win->importStlAction(), &QAction::triggered, [s]() {
    if (!s->file_op_callback) return;
    QFileDialog dialog(s->window, "Import STL", QString(), "STL Files (*.stl *.STL)");
    dialog.setFileMode(QFileDialog::ExistingFile);
    dialog.setAcceptMode(QFileDialog::AcceptOpen);
    dialog.setOption(QFileDialog::DontUseNativeDialog);
    if (dialog.exec() == QDialog::Accepted)
    {
      QString path = dialog.selectedFiles().value(0);
      if (!path.isEmpty())
        s->file_op_callback(path.toUtf8().constData(), 3);
    }
  });

  QObject::connect(win->exportStepAction(), &QAction::triggered, [s]() {
    if (!s->file_op_callback) return;
    QFileDialog dialog(s->window, "Export STEP", QString(), "STEP Files (*.step *.STEP)");
    dialog.setFileMode(QFileDialog::AnyFile);
    dialog.setAcceptMode(QFileDialog::AcceptSave);
    dialog.setOption(QFileDialog::DontUseNativeDialog);
    if (dialog.exec() == QDialog::Accepted)
    {
      QString path = dialog.selectedFiles().value(0);
      if (!path.isEmpty())
        s->file_op_callback(path.toUtf8().constData(), 1);
    }
  });

  QObject::connect(win->exportStlAction(), &QAction::triggered, [s]() {
    if (!s->file_op_callback) return;
    QFileDialog dialog(s->window, "Export STL", QString(), "STL Files (*.stl *.STL)");
    dialog.setFileMode(QFileDialog::AnyFile);
    dialog.setAcceptMode(QFileDialog::AcceptSave);
    dialog.setOption(QFileDialog::DontUseNativeDialog);
    if (dialog.exec() == QDialog::Accepted)
    {
      QString path = dialog.selectedFiles().value(0);
      if (!path.isEmpty())
        s->file_op_callback(path.toUtf8().constData(), 2);
    }
  });

  QObject::connect(win->importLispAction(), &QAction::triggered, [s]() {
    if (!s->file_op_callback) return;
    QFileDialog dialog(s->window, "Import Lisp", QString(), "Lisp Files (*.lisp *.LISP)");
    dialog.setFileMode(QFileDialog::ExistingFile);
    dialog.setAcceptMode(QFileDialog::AcceptOpen);
    dialog.setOption(QFileDialog::DontUseNativeDialog);
    if (dialog.exec() == QDialog::Accepted)
    {
      QString path = dialog.selectedFiles().value(0);
      if (!path.isEmpty())
      {
        QMessageBox warning(s->window);
        warning.setIcon(QMessageBox::Warning);
        warning.setWindowTitle(QStringLiteral("DANGEROUS: Importing Lisp Code"));
        warning.setText(QStringLiteral(
          "DANGEROUS: Importing Lisp Code\n\n"
          "You are about to execute arbitrary Lisp code from an external file. "
          "This code can perform malicious actions on your system, even if "
          "the file appears harmless or comes from a seemingly trustworthy source. "
          "Lisp code has full access to your system including:\n\n"
          "  \u2022 Reading, modifying, or deleting files\n"
          "  \u2022 Network access to send data\n"
          "  \u2022 Running shell commands\n\n"
          "You should only run code that you trust and whose contents "
          "you have verified. When in doubt, cancel."));
        warning.setStandardButtons(QMessageBox::Cancel | QMessageBox::Ignore);
        warning.setDefaultButton(QMessageBox::Cancel);
        warning.button(QMessageBox::Ignore)->setText(QStringLiteral("I understand the risk, import anyway"));
        if (warning.exec() == QMessageBox::Ignore)
          s->file_op_callback(path.toUtf8().constData(), 4);
      }
    }
  });

  QObject::connect(win->exportReplHistoryAction(), &QAction::triggered, [s]() {
    if (!s->file_op_callback) return;
    QFileDialog dialog(s->window, "Export REPL History", QString(), "Lisp Files (*.lisp *.LISP)");
    dialog.setFileMode(QFileDialog::AnyFile);
    dialog.setAcceptMode(QFileDialog::AcceptSave);
    dialog.setOption(QFileDialog::DontUseNativeDialog);
    if (dialog.exec() == QDialog::Accepted)
    {
      QString path = dialog.selectedFiles().value(0);
      if (!path.isEmpty())
        s->file_op_callback(path.toUtf8().constData(), 5);
    }
  });

  // Cancel import via status bar label click or Ctrl+G
  QObject::connect(win, &ViewerWindow::importCancelRequested, [s]() {
    if (s->file_op_callback)
      s->file_op_callback("", 99);
  });

  // Wire View menu actions
  QObject::connect(win->axisAction(), &QAction::toggled, [s](bool checked) {
    viewer_show_axis(s, checked ? 1 : 0);
  });
  QObject::connect(win->gridAction(), &QAction::toggled, [s](bool checked) {
    viewer_show_grid(s, checked ? 1 : 0);
  });
  QObject::connect(win->viewCubeAction(), &QAction::toggled, [s](bool checked) {
    viewer_show_viewcube(s, checked ? 1 : 0);
  });

  // Create and display ViewCube
  {
    Handle(AIS_ViewCube) viewCube = new ViewCubeWithCallback(s);
    Handle(Graphic3d_TransformPers) tpers =
      new Graphic3d_TransformPers(Graphic3d_TMF_TriedronPers, Aspect_TOTP_RIGHT_UPPER, NCollection_Vec2<int>(100, 100));
    viewCube->SetTransformPersistence(tpers);
    viewCube->SetDrawAxes(true);
    viewCube->SetResetCamera(true);
    s->viewCube = viewCube;
    s->context->Display(viewCube, false);
  }

  // Wire Help menu action
  QObject::connect(win->aboutAction(), &QAction::triggered, [win]() {
    showAboutDialog(win);
  });

  // Wire File > Quit
  QObject::connect(win->quitAction(), &QAction::triggered, [win]() {
    win->close();
  });

  // Wire scene tree
  SceneTreePanel* st = win->sceneTree();
  if (st)
  {
    st->setViewerState(s);
    st->setContext(s->context);
    QObject::connect(st, &SceneTreePanel::visibilityChanged, [s](const QString& name, bool visible) {
      viewer_set_shape_visible(s, name.toUtf8().constData(), visible ? 1 : 0);
    });
  }

  // Install wake receiver
  auto* receiver = new WakeReceiver(s);
  s->window->installEventFilter(receiver);
  QObject::connect(receiver, &QObject::destroyed, receiver, &QObject::deleteLater);

  // System color scheme change callback
#if QT_VERSION >= QT_VERSION_CHECK(6, 5, 0)
  QObject::connect(QApplication::styleHints(), &QStyleHints::colorSchemeChanged,
                   [s](Qt::ColorScheme scheme) {
                     if (s->color_scheme_callback)
                       s->color_scheme_callback(static_cast<int>(scheme));
                   });
#endif

  return s;
}

void viewer_destroy(occt_viewer vwr)
{
  if (!vwr) return;
  auto* s = (ViewerState*)vwr;
  if (s->window)
  {
    delete s->window;
    s->window = nullptr;
  }
  delete s;
}

void viewer_show(occt_viewer vwr)
{
  auto* s = (ViewerState*)vwr;
  if (s->window)
    s->window->show();
}

void viewer_run(occt_viewer vwr)
{
  auto* s = (ViewerState*)vwr;
  s->running = true;
  theApp->exec();
  s->running = false;
}

void viewer_quit(occt_viewer vwr)
{
  (void)vwr;
  if (theApp)
    theApp->quit();
}

int viewer_is_running(occt_viewer vwr)
{
  return ((ViewerState*)vwr)->running ? 1 : 0;
}

void viewer_post_event(occt_viewer vwr)
{
  auto* s = (ViewerState*)vwr;
  if (s->window)
    QCoreApplication::postEvent(s->window, new WakeEvent());
}

void viewer_post_event_delayed(occt_viewer vwr, int ms)
{
  auto* s = (ViewerState*)vwr;
  if (s->window)
    QTimer::singleShot(ms, [s]() {
      QCoreApplication::postEvent(s->window, new WakeEvent());
    });
}

void viewer_redraw(occt_viewer vwr)
{
  auto* s = (ViewerState*)vwr;
  if (s->widget)
    s->widget->update();
}

void viewer_sync_shapes(occt_viewer vwr, ShapeSyncItem* items, int count)
{
  if (!vwr) return;
  auto* s = (ViewerState*)vwr;

  // Build set of incoming names
  std::set<std::string> incoming;
  for (int i = 0; i < count; i++)
    incoming.insert(items[i].name);

  // Remove shapes not in incoming set
  std::vector<std::string> to_remove;
  for (auto& [name, ais] : s->shapes)
    if (!incoming.count(name))
      to_remove.push_back(name);
  auto docks = s->window->findChildren<SceneTreePanel*>();
  for (auto& name : to_remove)
  {
    auto it = s->shapes.find(name);
    if (it != s->shapes.end())
    {
      s->obj_to_name.erase(it->second.get());
      s->context->Remove(it->second, false);
      s->shapes.erase(it);
    }
    s->shape_names.erase(std::remove(s->shape_names.begin(), s->shape_names.end(), name), s->shape_names.end());
    for (auto* dock : docks)
      dock->removeShape(QString::fromUtf8(name.c_str()));
  }

  // Add/update shapes in incoming set
  for (int i = 0; i < count; i++)
  {
    auto& item = items[i];
    auto it = s->shapes.find(item.name);

    if (it != s->shapes.end())
    {
      // Shape exists — recreate AIS only if geometry changed
      if (item.shape_changed)
      {
        s->obj_to_name.erase(it->second.get());
        auto* shape = static_cast<TopoDS_Shape*>(item.shape_ptr);
        s->context->Remove(it->second, false);
        Handle(AIS_Shape) ais_shape = new AIS_Shape(*shape);
        if (item.checked)
        {
          s->context->Display(ais_shape, false);
          s->context->Activate(ais_shape, 0);
        }
        it->second = ais_shape;
        s->obj_to_name[ais_shape.get()] = item.name;
      }
      else
      {
        // Geometry unchanged — just sync visibility
        auto& ais = s->shapes[item.name];
        if (item.checked)
          s->context->Display(ais, false);
        else
          s->context->Erase(ais, false);
      }
    }
    else
    {
      // New shape
      auto* shape = static_cast<TopoDS_Shape*>(item.shape_ptr);
      Handle(AIS_Shape) ais_shape = new AIS_Shape(*shape);
      if (item.checked)
      {
        s->context->Display(ais_shape, false);
        s->context->Activate(ais_shape, 0);
      }
      s->shapes[item.name] = ais_shape;
      s->obj_to_name[ais_shape.get()] = item.name;
      s->shape_names.push_back(item.name);
      for (auto* dock : docks)
        dock->addShape(QString::fromUtf8(item.name));
    }

    // Sync tree checkbox and row visibility
    for (auto* dock : docks)
    {
      dock->setShapeCheckState(QString::fromUtf8(item.name), item.checked);
      dock->setShapeTreeVisible(QString::fromUtf8(item.name), item.show_in_tree);
    }
  }

  if (count > 0 && !s->widget->View()->Window().IsNull())
    s->widget->View()->FitAll();
}

void viewer_fit_all(occt_viewer vwr)
{
  auto* s = (ViewerState*)vwr;
  if (s->widget && !s->widget->View().IsNull() && !s->widget->View()->Window().IsNull())
  {
    s->widget->View()->FitAll();
    s->widget->update();
  }
}

void viewer_set_eval_callback(occt_viewer vwr, eval_fn fn)
{
  if (!vwr) return;
  auto* s = (ViewerState*)vwr;
  s->eval_callback = fn;
  auto docks = s->window->findChildren<REPLPanel*>();
  for (auto* dock : docks)
    dock->setEvalCallback(fn);
}

void viewer_set_file_op_callback(occt_viewer vwr, file_op_fn fn)
{
  ((ViewerState*)vwr)->file_op_callback = fn;
}

void viewer_append_repl_output(occt_viewer vwr, const char* text)
{
  if (!vwr || !text) return;
  auto* s = (ViewerState*)vwr;
  auto docks = s->window->findChildren<REPLPanel*>();
  QString qtext = QString::fromUtf8(text);
  for (auto* dock : docks)
    QMetaObject::invokeMethod(dock, "appendOutputSafe", Qt::QueuedConnection, Q_ARG(QString, qtext));
}

void viewer_set_repl_history_modifier(occt_viewer vwr, int mod)
{
  if (!vwr) return;
  auto* s = (ViewerState*)vwr;
  auto docks = s->window->findChildren<REPLPanel*>();
  for (auto* dock : docks)
    dock->setHistoryModifier(mod);
}

void viewer_set_repl_submit_modifier(occt_viewer vwr, int mod)
{
  if (!vwr) return;
  auto* s = (ViewerState*)vwr;
  auto docks = s->window->findChildren<REPLPanel*>();
  for (auto* dock : docks)
    dock->setSubmitModifier(mod);
}

void viewer_set_shape_visible(occt_viewer vwr, const char* name, int visible)
{
  auto* s = (ViewerState*)vwr;
  auto it = s->shapes.find(name);
  if (it != s->shapes.end())
  {
    if (visible)
      s->context->Display(it->second, false);
    else
      s->context->Erase(it->second, false);
    if (s->visibility_callback)
      s->visibility_callback(name, visible);
  }
}

void viewer_show_grid(occt_viewer vwr, int show)
{
  auto* s = (ViewerState*)vwr;
  if (!s->widget->Viewer().IsNull())
  {
    if (show)
      s->widget->Viewer()->ActivateGrid(Aspect_GT_Rectangular, Aspect_GDM_Lines);
    else
      s->widget->Viewer()->DeactivateGrid();
  }
  if (s->window && s->window->gridAction())
    s->window->gridAction()->setChecked(show ? true : false);
  viewer_redraw(vwr);
}

int viewer_is_grid_visible(occt_viewer vwr)
{
  auto* s = (ViewerState*)vwr;
  if (s->window && s->window->gridAction())
    return s->window->gridAction()->isChecked() ? 1 : 0;
  return 0;
}

void viewer_show_axis(occt_viewer vwr, int show)
{
  auto* s = (ViewerState*)vwr;
  if (!s->widget) return;

  if (s->axisTrihedron.IsNull())
  {
    Handle(Geom_Axis2Placement) axes = new Geom_Axis2Placement(gp::Origin(), gp::DZ(), gp::DX());
    s->axisTrihedron = new AIS_Trihedron(axes);
    s->axisTrihedron->SetDatumDisplayMode(Prs3d_DM_WireFrame);
    s->axisTrihedron->SetDrawArrows(true);
    s->axisTrihedron->SetSize(50.0);
    Handle(Graphic3d_TransformPers) tpers =
      new Graphic3d_TransformPers(Graphic3d_TMF_TriedronPers, Aspect_TOTP_LEFT_LOWER, NCollection_Vec2<int>(60, 60));
    s->axisTrihedron->SetTransformPersistence(tpers);
    if (show)
      s->context->Display(s->axisTrihedron, false);
    s->context->Deactivate(s->axisTrihedron);
  }
  else
  {
    if (show)
      s->context->Display(s->axisTrihedron, false);
    else
      s->context->Erase(s->axisTrihedron, false);
  }
  if (s->window && s->window->axisAction())
    s->window->axisAction()->setChecked(show ? true : false);
  viewer_redraw(vwr);
}

int viewer_is_axis_visible(occt_viewer vwr)
{
  auto* s = (ViewerState*)vwr;
  if (s->window && s->window->axisAction())
    return s->window->axisAction()->isChecked() ? 1 : 0;
  return 0;
}

// --- ViewCube ---

void viewer_show_viewcube(occt_viewer vwr, int show)
{
  auto* s = (ViewerState*)vwr;
  if (!s->widget || s->viewCube.IsNull()) return;

  if (show)
    s->context->Display(s->viewCube, false);
  else
    s->context->Erase(s->viewCube, false);

  if (s->window && s->window->viewCubeAction())
    s->window->viewCubeAction()->setChecked(show ? true : false);
  viewer_redraw(vwr);
}

int viewer_is_viewcube_visible(occt_viewer vwr)
{
  auto* s = (ViewerState*)vwr;
  if (s->window && s->window->viewCubeAction())
    return s->window->viewCubeAction()->isChecked() ? 1 : 0;
  return 1;
}

void viewer_set_view(occt_viewer vwr, int orientation)
{
  auto* s = (ViewerState*)vwr;
  if (s->widget && !s->widget->View().IsNull())
  {
    s->widget->View()->SetProj(static_cast<V3d_TypeOfOrientation>(orientation));
    // In Z-up convention, choose Up axis orthogonal to view direction:
    //   Top/Bottom (looking along Z): Up = Y
    //   Front/Back (looking along Y): Up = Z
    //   Left/Right (looking along X): Up = Z
    if (orientation == V3d_Zpos || orientation == V3d_Zneg)
      s->widget->View()->SetUp(V3d_Ypos);
    else
      s->widget->View()->SetUp(V3d_Zpos);
    s->currentOrientation = orientation;
    if (!s->viewCube.IsNull())
      s->viewCube->SetToUpdate();
    viewer_redraw(vwr);
  }
}

int viewer_get_view_orientation(occt_viewer vwr)
{
  auto* s = (ViewerState*)vwr;
  return s->currentOrientation;
}

void viewer_set_viewcube_callback(occt_viewer vwr, viewcube_fn fn)
{
  auto* s = (ViewerState*)vwr;
  s->viewcube_callback = fn;
}

void viewer_set_viewcube_color(occt_viewer vwr, double r, double g, double b)
{
  auto* s = (ViewerState*)vwr;
  if (!s || s->viewCube.IsNull()) return;
  s->viewCube->SetBoxColor(Quantity_Color(r, g, b, Quantity_TOC_RGB));
}

void viewer_set_viewcube_text_color(occt_viewer vwr, double r, double g, double b)
{
  auto* s = (ViewerState*)vwr;
  if (!s || s->viewCube.IsNull()) return;
  s->viewCube->SetTextColor(Quantity_Color(r, g, b, Quantity_TOC_RGB));
}

void viewer_set_viewcube_inner_color(occt_viewer vwr, double r, double g, double b)
{
  auto* s = (ViewerState*)vwr;
  if (!s || s->viewCube.IsNull()) return;
  s->viewCube->SetInnerColor(Quantity_Color(r, g, b, Quantity_TOC_RGB));
}

void viewer_set_viewcube_transparency(occt_viewer vwr, double t)
{
  auto* s = (ViewerState*)vwr;
  if (!s || s->viewCube.IsNull()) return;
  s->viewCube->SetTransparency(t);
}

void viewer_set_viewcube_size(occt_viewer vwr, double size)
{
  auto* s = (ViewerState*)vwr;
  if (!s || s->viewCube.IsNull()) return;
  s->viewCube->SetSize(size);
}

void viewer_set_viewcube_axis_color(occt_viewer vwr, int part, double r, double g, double b)
{
  auto* s = (ViewerState*)vwr;
  if (!s || s->viewCube.IsNull()) return;
  if (part < 0 || part > 2) return;
  static const Prs3d_DatumParts parts[] = {
    Prs3d_DatumParts_XAxis,
    Prs3d_DatumParts_YAxis,
    Prs3d_DatumParts_ZAxis
  };
  Quantity_Color col(r, g, b, Quantity_TOC_RGB);
  s->viewCube->Attributes()->DatumAspect()
    ->ShadingAspect(parts[part])->SetColor(col);
  s->viewCube->Attributes()->DatumAspect()
    ->TextAspect(parts[part])->SetColor(col);
}

void viewer_set_viewcube_draw_axes(occt_viewer vwr, int show)
{
  auto* s = (ViewerState*)vwr;
  if (!s || s->viewCube.IsNull()) return;
  if (show < 0)
    s->viewCube->SetDrawAxes(!s->viewCube->ToDrawAxes());
  else
    s->viewCube->SetDrawAxes(show ? true : false);
  s->context->Update(s->viewCube, true);
}

int viewer_get_viewcube_draw_axes(occt_viewer vwr)
{
  auto* s = (ViewerState*)vwr;
  if (!s || s->viewCube.IsNull()) return 1;
  return s->viewCube->ToDrawAxes() ? 1 : 0;
}

void viewer_set_viewcube_hilight_color(occt_viewer vwr, double r, double g, double b)
{
  auto* s = (ViewerState*)vwr;
  if (!s || s->viewCube.IsNull()) return;
  auto dynDrawer = s->viewCube->DynamicHilightAttributes();
  if (!dynDrawer.IsNull())
  {
    Quantity_Color col(r, g, b, Quantity_TOC_RGB);
    if (!dynDrawer->HasOwnShadingAspect())
      dynDrawer->SetupOwnShadingAspect();
    dynDrawer->ShadingAspect()->SetColor(col);
    dynDrawer->SetColor(col);
  }
}

void viewer_show_dock(occt_viewer vwr, const char* dock_name, int show)
{
  if (!vwr || !dock_name) return;
  auto* s = (ViewerState*)vwr;
  if (!s->window) return;

  QString qname = QString::fromUtf8(dock_name);
  QAction* action = nullptr;
  if (qname == "REPLPanel")
    action = s->window->replAction();
  else if (qname == "SceneTreePanel")
    action = s->window->sceneTreeAction();
  if (!action) return;

  if (show < 0)
    action->toggle();
  else
    action->setChecked(show ? true : false);
}

void viewer_set_drain_callback(occt_viewer vwr, drain_fn fn)
{
  ((ViewerState*)vwr)->drain_callback = fn;
}

void viewer_set_antialiasing(occt_viewer vwr, int enable)
{
  auto* s = (ViewerState*)vwr;
  if (s->widget && !s->widget->View().IsNull())
  {
    s->widget->View()->ChangeRenderingParams().IsAntialiasingEnabled = enable;
    s->widget->View()->ChangeRenderingParams().NbMsaaSamples = enable ? 4 : 0;
  }
}

void viewer_set_stylesheet(occt_viewer vwr, const char* qss)
{
  (void)vwr;
  if (!theApp || !qss) return;
  QString qssStr = QString::fromUtf8(qss);

  // Set QPalette BEFORE setStyleSheet -- the stylesheet overrides the palette,
  // but only for roles that QSS properties control (e.g., WindowText via `color`).
  // ButtonText is NOT controlled by QSS on non-button widgets like QFileDialog,
  // so the stylesheet will preserve our ButtonText value from the app palette.
  // This is needed because QFileDialog's parent-directory icon uses
  // QCommonStyle::standardIcon(SP_FileDialogToParent) which reads ButtonText.
  bool dark = qssStr.contains("#1e1e1e");
  QPalette pal = theApp->palette();
  if (dark) {
    pal.setColor(QPalette::WindowText, QColor("#e0e0e0"));
    pal.setColor(QPalette::ButtonText, QColor("#e0e0e0"));
    pal.setColor(QPalette::Text, QColor("#f0f0f0"));
  } else {
    pal.setColor(QPalette::WindowText, QColor("#1a1a1a"));
    pal.setColor(QPalette::ButtonText, QColor("#1a1a1a"));
    pal.setColor(QPalette::Text, QColor("#1a1a1a"));
  }
  theApp->setPalette(pal);

  theApp->setStyleSheet(qssStr);
}

void viewer_set_icon_palette(occt_viewer vwr, const char* fg_color)
{
  (void)vwr;
  if (!theApp || !fg_color) return;
  QPalette pal = theApp->palette();
  QColor fg(QString::fromUtf8(fg_color));
  if (!fg.isValid()) return;
  pal.setColor(QPalette::WindowText, fg);
  pal.setColor(QPalette::ButtonText, fg);
  pal.setColor(QPalette::Text, fg);
  theApp->setPalette(pal);
}

int viewer_color_scheme(occt_viewer vwr)
{
  (void)vwr;
#if QT_VERSION >= QT_VERSION_CHECK(6, 5, 0)
  return static_cast<int>(QApplication::styleHints()->colorScheme());
#else
  return 0;
#endif
}

void viewer_set_color_scheme_callback(occt_viewer vwr, color_scheme_fn fn)
{
  auto* s = (ViewerState*)vwr;
  s->color_scheme_callback = fn;
}

void viewer_set_placeholder_color(occt_viewer vwr, int r, int g, int b)
{
  (void)vwr;
  if (theApp)
  {
    QPalette pal = theApp->palette();
    pal.setColor(QPalette::PlaceholderText, QColor(r, g, b));
    theApp->setPalette(pal);
  }
}

void* viewer_get_view(occt_viewer vwr)
{
  auto* s = (ViewerState*)vwr;
  if (s->widget && !s->widget->View().IsNull())
    return (void*)&s->widget->View();
  return nullptr;
}

void* viewer_get_trihedron(occt_viewer vwr)
{
  auto* s = (ViewerState*)vwr;
  if (!s->axisTrihedron.IsNull())
    return (void*)&s->axisTrihedron;
  return nullptr;
}

void viewer_set_trihedron_text_color(occt_viewer vwr, int part, double r, double g, double b)
{
  auto* s = (ViewerState*)vwr;
  if (!s || s->axisTrihedron.IsNull()) return;
  if (part < 0 || part > 2) return;
  static const Prs3d_DatumParts parts[] = {
    Prs3d_DatumParts_XAxis,
    Prs3d_DatumParts_YAxis,
    Prs3d_DatumParts_ZAxis
  };
  s->axisTrihedron->SetTextColor(parts[part], Quantity_Color(r, g, b, Quantity_TOC_RGB));
}

void viewer_set_status_text(occt_viewer vwr, const char* text)
{
  auto* s = (ViewerState*)vwr;
  if (s->window && text)
    s->window->setStatusText(text);
}

void viewer_set_import_status(occt_viewer vwr, int show, int current, int total)
{
  auto* s = (ViewerState*)vwr;
  if (!s->window) return;
  auto* label = s->window->importStatusLabel();
  if (!label) return;
  if (show)
  {
    label->setText(QString("Importing %1/%2...").arg(current).arg(total));
    label->setVisible(true);
  }
  else
  {
    label->setVisible(false);
  }
}

void viewer_show_message(occt_viewer vwr, const char* title, const char* message)
{
  auto* s = (ViewerState*)vwr;
  if (!s || !s->window) return;
  QMessageBox::warning(s->window, QString::fromUtf8(title), QString::fromUtf8(message));
}

void viewer_set_visibility_callback(occt_viewer vwr, visibility_fn fn)
{
  auto* s = (ViewerState*)vwr;
  s->visibility_callback = fn;
}

// ========== Selection API ==========

void* viewer_get_context(occt_viewer vwr)
{
  auto* s = (ViewerState*)vwr;
  return (void*)&s->context;
}

void* viewer_get_ais_object(occt_viewer vwr, const char* name)
{
  auto* s = (ViewerState*)vwr;
  auto it = s->shapes.find(name);
  if (it != s->shapes.end())
    return (void*)&it->second;
  return nullptr;
}

void viewer_set_selection_callback(occt_viewer vwr, selection_changed_fn fn)
{
  auto* s = (ViewerState*)vwr;
  s->selection_callback = fn;
}

void viewer_set_tree_selection_callback(occt_viewer vwr, tree_selection_fn fn)
{
  auto* s = (ViewerState*)vwr;
  s->tree_callback = fn;
}

void viewer_set_mouse_selection_scheme(occt_viewer vwr, int key, int scheme)
{
  auto* s = (ViewerState*)vwr;
  s->mouse_schemes[key] = scheme;
}

int viewer_is_shape_selected(occt_viewer vwr, const char* name)
{
  auto* s = (ViewerState*)vwr;
  if (!s || !name) return 0;
  auto it = s->shapes.find(name);
  if (it == s->shapes.end()) return 0;
  return s->context->IsSelected(it->second) ? 1 : 0;
}

void viewer_select_names(occt_viewer vwr, const char** names, int count)
{
  auto* s = (ViewerState*)vwr;
  if (!s) return;

  s->context->ClearSelected(false);
  for (int i = 0; i < count; i++)
  {
    auto it = s->shapes.find(names[i]);
    if (it != s->shapes.end())
      s->context->AddOrRemoveSelected(it->second, false);
  }
  s->context->HilightSelected(true);
}

void viewer_sync_tree_selection(occt_viewer vwr)
{
  auto* s = (ViewerState*)vwr;
  if (!s || !s->window) return;

  std::set<std::string> selected;
  for (s->context->InitSelected(); s->context->MoreSelected(); s->context->NextSelected())
  {
    auto obj = s->context->SelectedInteractive();
    auto it = s->obj_to_name.find(obj.get());
    if (it != s->obj_to_name.end())
      selected.insert(it->second);
  }

  auto docks = s->window->findChildren<SceneTreePanel*>();
  for (auto* dock : docks)
    dock->syncSelection(selected);
}
