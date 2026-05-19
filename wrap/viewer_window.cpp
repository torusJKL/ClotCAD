#include "viewer_window.h"
#include "viewer_widget.h"
#include "repl_panel.h"
#include "scene_tree_panel.h"

#include <Standard_WarningsDisable.hxx>
#include <QApplication>
#include <QHBoxLayout>
#include <Standard_WarningsRestore.hxx>

ViewerWindow::ViewerWindow(const char* title, int width, int height)
{
  setWindowTitle(QString::fromUtf8(title));
  resize(width, height);

  myViewport = new ViewerWidget(this);
  setCentralWidget(myViewport);

  setupMenus();
  setupPanels();
  setupStatusBar();
}

void ViewerWindow::setupMenus()
{
  QMenuBar* mb = menuBar();

  QMenu* fileMenu = mb->addMenu(tr("&File"));
  QMenu* importMenu = fileMenu->addMenu(tr("&Import"));
  importMenu->addAction(tr("&STEP"));
  importMenu->addAction(tr("S&TL"));

  QMenu* exportMenu = fileMenu->addMenu(tr("&Export"));
  exportMenu->addAction(tr("&STEP"));
  exportMenu->addAction(tr("S&TL"));

  QMenu* viewMenu = mb->addMenu(tr("&View"));
  viewMenu->addAction(tr("&REPL"))->setCheckable(true);
  viewMenu->addAction(tr("&Scene Tree"))->setCheckable(true);
  viewMenu->addSeparator();
  viewMenu->addAction(tr("&Axis"))->setCheckable(true);
  viewMenu->addAction(tr("&Grid"))->setCheckable(true);
}

void ViewerWindow::setupStatusBar()
{
  QStatusBar* sb = statusBar();
  myShapeCountLabel = new QLabel(tr("Displaying 0 shapes"));
  myFpsLabel = new QLabel(this);
  sb->addWidget(myShapeCountLabel);
  sb->addPermanentWidget(myFpsLabel);
}

void ViewerWindow::setupPanels()
{
  myRepl = new REPLPanel(this);
  addDockWidget(Qt::RightDockWidgetArea, myRepl);
  myRepl->setFeatures(QDockWidget::DockWidgetClosable | QDockWidget::DockWidgetMovable);

  mySceneTree = new SceneTreePanel(this);
  addDockWidget(Qt::LeftDockWidgetArea, mySceneTree);
  mySceneTree->setFeatures(QDockWidget::DockWidgetClosable | QDockWidget::DockWidgetMovable);
}

void ViewerWindow::updateShapeCount(int count)
{
  myShapeCountLabel->setText(tr("Displaying %1 shapes").arg(count));
}

void ViewerWindow::updateFps(double fps)
{
  myFpsLabel->setText(tr("FPS: %1").arg(fps, 0, 'f', 0));
}

void ViewerWindow::closeEvent(QCloseEvent* event)
{
  emit windowClosed();
  QApplication::quit();
  event->accept();
}
