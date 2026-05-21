#include "occt_viewer.h"
#include "viewer_window.h"
#include "viewer_widget.h"
#include "repl_panel.h"
#include "scene_tree_panel.h"
#include "OcctQtTools.h"

#include <AIS_Shape.hxx>
#include <AIS_Trihedron.hxx>
#include <AIS_InteractiveContext.hxx>
#include <Geom_Axis2Placement.hxx>
#include <Graphic3d_TransformPers.hxx>
#include <Graphic3d_TransModeFlags.hxx>
#include <Aspect_TypeOfTriedronPosition.hxx>
#include <Prs3d_DatumMode.hxx>
#include <gp.hxx>
#include <TopoDS_Shape.hxx>
#include <V3d_View.hxx>


#include <Standard_WarningsDisable.hxx>
#include <QApplication>
#include <QObject>
#include <QEvent>
#include <QCoreApplication>
#include <QFileDialog>
#include <QDockWidget>
#include <QStyleHints>
#include <map>
#include <string>
#include <vector>
#include <cstring>
#include <algorithm>
#include <Standard_WarningsRestore.hxx>

static const QEvent::Type WakeEventType = static_cast<QEvent::Type>(QEvent::User + 1);

class WakeEvent : public QEvent
{
public:
  WakeEvent() : QEvent(WakeEventType) {}
};

struct ViewerState {
  int visibleShapeCount() const {
    int n = 0;
    for (auto& [name, shape] : shapes)
      if (context->IsDisplayed(shape)) n++;
    return n;
  }
  ViewerWindow* window = nullptr;
  ViewerWidget* widget = nullptr;

  Handle(AIS_InteractiveContext) context;

  // Transient name->AIS_Shape cache (for name-based erase/lookup in OCCT calls)
  std::map<std::string, Handle(AIS_Shape), std::less<>> shapes;
  std::vector<std::string> shape_names;

  Handle(AIS_Trihedron) axisTrihedron;

  // Callbacks
  eval_fn eval_callback = nullptr;
  file_op_fn file_op_callback = nullptr;
  drain_fn drain_callback = nullptr;
  color_scheme_fn color_scheme_callback = nullptr;
  visibility_fn visibility_callback = nullptr;

  // Cache for viewer_get_shape_name
  mutable std::string name_cache;

  // Running state
  bool running = false;
};

static QApplication* theApp = nullptr;
static int theArgc = 1;
static const char* theArgv[] = {"cl-occt-viewer", nullptr};

static void ensureQApplication()
{
  if (!theApp)
  {
    qputenv("QT_QPA_PLATFORM", "xcb");
    OcctQtTools::qtGlPlatformSetup();
    theApp = new QApplication(theArgc, const_cast<char**>(theArgv));
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

// ========== C API ==========

occt_viewer viewer_create(const char* title, int width, int height)
{
  ensureQApplication();
  auto* s = new ViewerState();
  auto* win = new ViewerWindow(title, width, height);
  s->window = win;
  s->widget = win->viewport();
  s->context = win->viewport()->Context();

  // Wire File menu actions
  QObject::connect(win->importStepAction(), &QAction::triggered, [s]() {
    if (!s->file_op_callback) return;
    QFileDialog dialog(s->window, "Import STEP", QString(), "STEP Files (*.step *.STEP)");
    dialog.setFileMode(QFileDialog::ExistingFile);
    dialog.setAcceptMode(QFileDialog::AcceptOpen);
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
    if (dialog.exec() == QDialog::Accepted)
    {
      QString path = dialog.selectedFiles().value(0);
      if (!path.isEmpty())
        s->file_op_callback(path.toUtf8().constData(), 2);
    }
  });

  // Wire View menu actions
  QObject::connect(win->axisAction(), &QAction::toggled, [s](bool checked) {
    viewer_show_axis(s, checked ? 1 : 0);
  });
  QObject::connect(win->gridAction(), &QAction::toggled, [s](bool checked) {
    viewer_show_grid(s, checked ? 1 : 0);
  });

  // Wire scene tree context
  SceneTreePanel* st = win->sceneTree();
  if (st)
  {
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

void viewer_redraw(occt_viewer vwr)
{
  auto* s = (ViewerState*)vwr;
  if (s->widget)
    s->widget->update();
}

void viewer_put_shape(occt_viewer vwr, occt_shape shape_ptr, const char* name)
{
  if (!vwr || !shape_ptr || !name) return;
  auto* s = (ViewerState*)vwr;
  auto* shape = static_cast<TopoDS_Shape*>(shape_ptr);

  Handle(AIS_Shape) ais_shape = new AIS_Shape(*shape);
  s->context->Display(ais_shape, false);

  auto it = s->shapes.find(name);
  if (it != s->shapes.end())
  {
    s->context->Remove(it->second, false);
    it->second = ais_shape;
  }
  else
  {
    s->shapes[name] = ais_shape;
    s->shape_names.push_back(name);
    auto docks = s->window->findChildren<SceneTreePanel*>();
    for (auto* dock : docks)
      dock->addShape(QString::fromUtf8(name));
  }

  if (!s->widget->View()->Window().IsNull())
    s->widget->View()->FitAll();
}

void viewer_remove_shape(occt_viewer vwr, const char* name)
{
  if (!vwr || !name) return;
  auto* s = (ViewerState*)vwr;
  auto it = s->shapes.find(name);
  if (it != s->shapes.end())
  {
    s->context->Remove(it->second, false);
    s->shapes.erase(it);
    auto& names = s->shape_names;
    names.erase(std::remove(names.begin(), names.end(), name), names.end());
    auto docks = s->window->findChildren<SceneTreePanel*>();
    for (auto* dock : docks)
      dock->removeShape(QString::fromUtf8(name));
  }
}

void viewer_clear(occt_viewer vwr)
{
  if (!vwr) return;
  auto* s = (ViewerState*)vwr;
  for (auto& [name, shape] : s->shapes)
    s->context->Remove(shape, false);
  s->shapes.clear();
  s->shape_names.clear();
  auto docks = s->window->findChildren<SceneTreePanel*>();
  for (auto* dock : docks)
    dock->clearAll();
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

int viewer_get_shape_count(occt_viewer vwr)
{
  return (int)((ViewerState*)vwr)->shapes.size();
}

const char* viewer_get_shape_name(occt_viewer vwr, int idx)
{
  auto* s = (ViewerState*)vwr;
  if (idx < 0 || idx >= (int)s->shape_names.size())
    return nullptr;
  s->name_cache = s->shape_names[idx];
  return s->name_cache.c_str();
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

int viewer_is_shape_visible(occt_viewer vwr, const char* name)
{
  auto* s = (ViewerState*)vwr;
  auto it = s->shapes.find(name);
  if (it != s->shapes.end())
    return s->context->IsDisplayed(it->second) ? 1 : 0;
  return 0;
}

void viewer_notify_shape_change(occt_viewer vwr)
{
  viewer_redraw(vwr);
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
    Handle(Geom_Axis2Placement) axes = new Geom_Axis2Placement(gp::Origin(), gp::DX(), gp::DY());
    s->axisTrihedron = new AIS_Trihedron(axes);
    s->axisTrihedron->SetDatumDisplayMode(Prs3d_DM_WireFrame);
    s->axisTrihedron->SetDrawArrows(true);
    s->axisTrihedron->SetSize(50.0);
    Handle(Graphic3d_TransformPers) tpers =
      new Graphic3d_TransformPers(Graphic3d_TMF_TriedronPers, Aspect_TOTP_LEFT_LOWER, NCollection_Vec2<int>(60, 60));
    s->axisTrihedron->SetTransformPersistence(tpers);
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
  if (theApp && qss)
    theApp->setStyleSheet(QString::fromUtf8(qss));
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

int viewer_get_visible_shape_count(occt_viewer vwr)
{
  auto* s = (ViewerState*)vwr;
  return s->visibleShapeCount();
}

void viewer_set_status_text(occt_viewer vwr, const char* text)
{
  auto* s = (ViewerState*)vwr;
  if (s->window && text)
    s->window->setStatusText(text);
}

void viewer_set_visibility_callback(occt_viewer vwr, visibility_fn fn)
{
  auto* s = (ViewerState*)vwr;
  s->visibility_callback = fn;
}
