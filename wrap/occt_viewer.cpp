#include "occt_viewer.h"
#include "viewer_window.h"
#include "viewer_widget.h"
#include "repl_panel.h"
#include "scene_tree_panel.h"
#include "OcctQtTools.h"

#include <AIS_Shape.hxx>
#include <AIS_Trihedron.hxx>
#include <AIS_InteractiveContext.hxx>
#include <TopoDS_Shape.hxx>
#include <V3d_View.hxx>

#include <Standard_WarningsDisable.hxx>
#include <QApplication>
#include <QObject>
#include <QEvent>
#include <QMetaObject>
#include <QCoreApplication>
#include <QTimer>
#include <QDateTime>
#include <QFileDialog>
#include <QDockWidget>
#include <map>
#include <string>
#include <vector>
#include <cstring>
#include <algorithm>
#include <mutex>
#include <queue>
#include <Standard_WarningsRestore.hxx>

// --- Custom event for inter-thread wake ---
static const QEvent::Type WakeEventType = static_cast<QEvent::Type>(QEvent::User + 1);

class WakeEvent : public QEvent
{
public:
  WakeEvent() : QEvent(WakeEventType) {}
};

// --- ViewerState ---
struct ViewerState {
  ViewerWindow* window = nullptr;
  ViewerWidget* widget = nullptr;

  // OCCT handles (mirrored from widget for C API convenience)
  Handle(AIS_InteractiveContext) context;

  // Shape storage
  std::map<std::string, Handle(AIS_Shape), std::less<>> shapes;
  std::vector<std::string> shape_names;

  // Callbacks
  eval_fn eval_callback = nullptr;
  file_op_fn file_op_callback = nullptr;
  drain_fn drain_callback = nullptr;

  // Grid / axis state
  bool axis_visible = true;
  bool grid_visible = true;

  // Queue for inter-thread communication
  std::mutex queue_mutex;
  std::queue<std::function<void()>> pending_actions;

  // Running state
  bool running = false;

  // Guard against redraw during modal file dialogs (avoids division-by-zero in OCCT rendering)
  bool processing_modal = false;

  // Timer for periodic updates (stopped during modals to prevent race conditions)
  QTimer* timer = nullptr;

  // Cache for viewer_get_shape_name
  mutable std::string name_cache;
};

// --- QApplication singleton management ---
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

// --- Wake event receiver object (installed as event filter on ViewerWindow) ---
class WakeReceiver : public QObject
{
public:
  ViewerState* state;
  WakeReceiver(ViewerState* s) : QObject(), state(s) {}
  bool eventFilter(QObject* watched, QEvent* e) override
  {
    if (e->type() == WakeEventType)
    {
      // Skip processing during modal file dialogs to avoid crashes
      if (!state->processing_modal)
      {
        // Drain the Lisp-side queue (shape changes from worker thread)
        if (state->drain_callback)
          state->drain_callback();
        // Trigger a redraw after processing queued changes
        if (state->widget)
          state->widget->update();
      }
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

  // Setup menu actions
  QMenuBar* mb = win->menuBar();
  QList<QAction*> actions = mb->actions();
  for (QAction* fileAction : actions)
  {
    if (fileAction->text() == "&File")
    {
      QMenu* fileMenu = fileAction->menu();
      if (!fileMenu) continue;
      QList<QAction*> fileActions = fileMenu->actions();
      for (QAction* importAction : fileActions)
      {
        if (importAction->text() == "&Import")
        {
          QMenu* importMenu = importAction->menu();
          if (!importMenu) continue;
          QList<QAction*> importItems = importMenu->actions();
          for (QAction* item : importItems)
          {
            if (item->text() == "&STEP")
              QObject::connect(item, &QAction::triggered, [s]() {
                if (s->file_op_callback)
                {
                  s->widget->myProcessingModal = true;
                  s->processing_modal = true;
                  if (s->timer) s->timer->stop();
                  QFileDialog dialog(s->window, "Import STEP", QString(), "STEP Files (*.step *.STEP)");
                  dialog.setOption(QFileDialog::DontUseNativeDialog);
                  dialog.setFileMode(QFileDialog::ExistingFile);
                  dialog.setAcceptMode(QFileDialog::AcceptOpen);
                  QString path;
                  if (dialog.exec() == QDialog::Accepted)
                    path = dialog.selectedFiles().value(0);
                  if (s->timer) s->timer->start();
                  s->processing_modal = false;
                  s->widget->myProcessingModal = false;
                  if (!path.isEmpty())
                    s->file_op_callback(path.toUtf8().constData(), 0);
                }
              });
            else if (item->text() == "S&TL")
              QObject::connect(item, &QAction::triggered, [s]() {
                if (s->file_op_callback)
                {
                  s->widget->myProcessingModal = true;
                  s->processing_modal = true;
                  if (s->timer) s->timer->stop();
                  QFileDialog dialog(s->window, "Import STL", QString(), "STL Files (*.stl *.STL)");
                  dialog.setOption(QFileDialog::DontUseNativeDialog);
                  dialog.setFileMode(QFileDialog::ExistingFile);
                  dialog.setAcceptMode(QFileDialog::AcceptOpen);
                  QString path;
                  if (dialog.exec() == QDialog::Accepted)
                    path = dialog.selectedFiles().value(0);
                  if (s->timer) s->timer->start();
                  s->processing_modal = false;
                  s->widget->myProcessingModal = false;
                  if (!path.isEmpty())
                    s->file_op_callback(path.toUtf8().constData(), 3);
                }
              });
          }
        }
        else if (importAction->text() == "&Export")
        {
          QMenu* exportMenu = importAction->menu();
          if (!exportMenu) continue;
          QList<QAction*> exportItems = exportMenu->actions();
          for (QAction* item : exportItems)
          {
            if (item->text() == "&STEP")
              QObject::connect(item, &QAction::triggered, [s, item]() {
                if (s->file_op_callback && !s->shapes.empty())
                {
                  s->widget->myProcessingModal = true;
                  s->processing_modal = true;
                  if (s->timer) s->timer->stop();
                  QFileDialog dialog(s->window, "Export STEP", QString(), "STEP Files (*.step *.STEP)");
                  dialog.setOption(QFileDialog::DontUseNativeDialog);
                  dialog.setFileMode(QFileDialog::AnyFile);
                  dialog.setAcceptMode(QFileDialog::AcceptSave);
                  QString path;
                  if (dialog.exec() == QDialog::Accepted)
                    path = dialog.selectedFiles().value(0);
                  if (s->timer) s->timer->start();
                  s->processing_modal = false;
                  s->widget->myProcessingModal = false;
                  if (!path.isEmpty())
                    s->file_op_callback(path.toUtf8().constData(), 1);
                }
              });
            else if (item->text() == "S&TL")
              QObject::connect(item, &QAction::triggered, [s, item]() {
                if (s->file_op_callback && !s->shapes.empty())
                {
                  s->widget->myProcessingModal = true;
                  s->processing_modal = true;
                  if (s->timer) s->timer->stop();
                  QFileDialog dialog(s->window, "Export STL", QString(), "STL Files (*.stl *.STL)");
                  dialog.setOption(QFileDialog::DontUseNativeDialog);
                  dialog.setFileMode(QFileDialog::AnyFile);
                  dialog.setAcceptMode(QFileDialog::AcceptSave);
                  QString path;
                  if (dialog.exec() == QDialog::Accepted)
                    path = dialog.selectedFiles().value(0);
                  if (s->timer) s->timer->start();
                  s->processing_modal = false;
                  s->widget->myProcessingModal = false;
                  if (!path.isEmpty())
                    s->file_op_callback(path.toUtf8().constData(), 2);
                }
              });
          }
        }
      }
    }
  }

  // Wire view menu
  for (QAction* viewAction : actions)
  {
    if (viewAction->text() == "&View")
    {
      QMenu* viewMenu = viewAction->menu();
      if (!viewMenu) continue;
      for (QAction* va : viewMenu->actions())
      {
        if (va->text() == "&Axis")
        {
          va->setChecked(true);
          QObject::connect(va, &QAction::toggled, [s](bool checked) {
            viewer_show_axis(s, checked ? 1 : 0);
          });
        }
        else if (va->text() == "&Grid")
        {
          va->setChecked(true);
          QObject::connect(va, &QAction::toggled, [s](bool checked) {
            viewer_show_grid(s, checked ? 1 : 0);
          });
        }
      }
    }
  }

  // Wire scene tree context
  SceneTreePanel* st = s->window->sceneTree();
  if (st)
  {
    st->setContext(s->context);
    QObject::connect(st, &SceneTreePanel::visibilityChanged, [s](const QString& name, bool visible) {
      QByteArray nameUtf8 = name.toUtf8();
      viewer_set_shape_visible(s, nameUtf8.constData(), visible ? 1 : 0);
    });
  }

  // Install wake receiver
  auto* receiver = new WakeReceiver(s);
  s->window->installEventFilter(receiver);
  QObject::connect(receiver, &QObject::destroyed, receiver, &QObject::deleteLater);

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
  // Start a timer to update FPS and shape count in status bar
  s->timer = new QTimer(s->window);
  QObject::connect(s->timer, &QTimer::timeout, [s]() {
    if (s->widget)
    {
      s->window->updateShapeCount((int)s->shapes.size());
      // FPS from ImGui style — use timer since we don't have a render loop
      static int frameCount = 0;
      static qint64 lastTime = QDateTime::currentMSecsSinceEpoch();
      frameCount++;
      qint64 now = QDateTime::currentMSecsSinceEpoch();
      if (now - lastTime >= 1000)
      {
        s->window->updateFps(frameCount * 1000.0 / (now - lastTime));
        frameCount = 0;
        lastTime = now;
      }
    }
    if (!s->processing_modal)
      viewer_redraw(s);
  });
  s->timer->start(100); // update 10 times per second

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

  auto it = s->shapes.find(name);
  Handle(AIS_Shape) ais_shape = new AIS_Shape(*shape);
  s->context->Display(ais_shape, false);

  if (it != s->shapes.end())
  {
    s->context->Remove(it->second, false);
    it->second = ais_shape;
  }
  else
  {
    s->shapes[name] = ais_shape;
    s->shape_names.push_back(name);
    // Find scene tree dock
    auto docks = s->window->findChildren<SceneTreePanel*>();
    for (auto* dock : docks)
      dock->addShape(QString::fromUtf8(name));
  }

  if (!s->processing_modal && !s->widget->View()->Window().IsNull())
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
  ((ViewerState*)vwr)->eval_callback = fn;
  // Propagate to REPL panel
  auto* s = (ViewerState*)vwr;
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
  s->grid_visible = show;
  if (!s->widget->Viewer().IsNull())
  {
    if (show)
      s->widget->Viewer()->ActivateGrid(Aspect_GT_Rectangular, Aspect_GDM_Lines);
    else
      s->widget->Viewer()->DeactivateGrid();
  }
  viewer_redraw(vwr);
}

int viewer_is_grid_visible(occt_viewer vwr)
{
  return ((ViewerState*)vwr)->grid_visible ? 1 : 0;
}

void viewer_show_axis(occt_viewer vwr, int show)
{
  auto* s = (ViewerState*)vwr;
  s->axis_visible = show;
  if (s->widget)
  {
    Handle(AIS_Trihedron) axis = s->widget->Axis();
    if (!axis.IsNull())
    {
      if (show)
        s->context->Display(axis, false);
      else
        s->context->Erase(axis, false);
    }
  }
  viewer_redraw(vwr);
}

int viewer_is_axis_visible(occt_viewer vwr)
{
  return ((ViewerState*)vwr)->axis_visible ? 1 : 0;
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
