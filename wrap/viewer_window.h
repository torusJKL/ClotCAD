#ifndef VIEWER_WINDOW_H
#define VIEWER_WINDOW_H

#include <Standard_WarningsDisable.hxx>
#include <QMainWindow>
#include <QDockWidget>
#include <QStatusBar>
#include <QMenuBar>
#include <QMenu>
#include <QAction>
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

  QAction* importStepAction() const { return myImportStepAction; }
  QAction* importStlAction() const { return myImportStlAction; }
  QAction* exportStepAction() const { return myExportStepAction; }
  QAction* exportStlAction() const { return myExportStlAction; }
  QAction* axisAction() const { return myAxisAction; }
  QAction* gridAction() const { return myGridAction; }
  QAction* replAction() const { return myReplAction; }
  QAction* sceneTreeAction() const { return mySceneTreeAction; }

signals:
  void windowClosed();

public slots:
  void setStatusText(const char* text);
  void updateFps(double fps);

protected:
  void closeEvent(QCloseEvent* event) override;

private:
  void setupMenus();
  void setupStatusBar();
  void setupPanels();
  bool eventFilter(QObject* obj, QEvent* event) override;

  ViewerWidget* myViewport = nullptr;
  REPLPanel* myRepl = nullptr;
  SceneTreePanel* mySceneTree = nullptr;

  QAction* myReplAction = nullptr;
  QAction* mySceneTreeAction = nullptr;
  QAction* myImportStepAction = nullptr;
  QAction* myImportStlAction = nullptr;
  QAction* myExportStepAction = nullptr;
  QAction* myExportStlAction = nullptr;
  QAction* myAxisAction = nullptr;
  QAction* myGridAction = nullptr;

  QLabel* myShapeCountLabel = nullptr;
  QLabel* myFpsLabel = nullptr;
};

#endif
