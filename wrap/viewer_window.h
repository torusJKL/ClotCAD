#ifndef VIEWER_WINDOW_H
#define VIEWER_WINDOW_H

#include <Standard_WarningsDisable.hxx>
#include <QMainWindow>
#include <QDockWidget>
#include <QStatusBar>
#include <QMenuBar>
#include <QMenu>
#include <QAction>
#include <QTimer>
#include <QLabel>
#include <QCloseEvent>
#include <Standard_WarningsRestore.hxx>

class ViewerWidget;
class REPLPanel;
class SceneTreePanel;

class ViewerWindow : public QMainWindow
{
  Q_OBJECT
public:
  ViewerWindow(const char* title, int width, int height);
  ~ViewerWindow() = default;

  ViewerWidget* viewport() const { return myViewport; }
  REPLPanel* replPanel() const { return myRepl; }
  SceneTreePanel* sceneTree() const { return mySceneTree; }

signals:
  void windowClosed();

public slots:
  void updateShapeCount(int count);
  void updateFps(double fps);

protected:
  void closeEvent(QCloseEvent* event) override;

private:
  void setupMenus();
  void setupStatusBar();
  void setupPanels();

  ViewerWidget* myViewport = nullptr;
  REPLPanel* myRepl = nullptr;
  SceneTreePanel* mySceneTree = nullptr;

  QLabel* myShapeCountLabel = nullptr;
  QLabel* myFpsLabel = nullptr;
};

#endif
