#include "viewer_window.h"
#include "viewer_widget.h"
#include "repl_panel.h"
#include "scene_tree_panel.h"

#include <Standard_WarningsDisable.hxx>
#include <QApplication>
#include <QHBoxLayout>
#include <QEvent>
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

  auto* cancelShortcut = new QShortcut(QKeySequence("Ctrl+G"), this);
  connect(cancelShortcut, &QShortcut::activated, this, &ViewerWindow::importCancelRequested);
}

void ViewerWindow::setupMenus()
{
  QMenuBar* mb = menuBar();

  QMenu* fileMenu = mb->addMenu(tr("&File"));
  myImportStepAction = fileMenu->addAction(tr("Import &STEP..."));
  myImportStlAction = fileMenu->addAction(tr("Import S&TL..."));
  myImportLispAction = fileMenu->addAction(tr("Import &Lisp..."));
  fileMenu->addSeparator();
  myExportStepAction = fileMenu->addAction(tr("Export &STEP..."));
  myExportStlAction = fileMenu->addAction(tr("Export S&TL..."));
  myExportReplHistoryAction = fileMenu->addAction(tr("Export REPL &History..."));

  QMenu* viewMenu = mb->addMenu(tr("&View"));
  myReplAction = viewMenu->addAction(tr("&REPL"));
  myReplAction->setCheckable(true);
  myReplAction->setChecked(true);
  mySceneTreeAction = viewMenu->addAction(tr("&Scene Tree"));
  mySceneTreeAction->setCheckable(true);
  mySceneTreeAction->setChecked(true);
  viewMenu->addSeparator();
  myAxisAction = viewMenu->addAction(tr("&Axis"));
  myAxisAction->setCheckable(true);
  myAxisAction->setChecked(false);
  myGridAction = viewMenu->addAction(tr("&Grid"));
  myGridAction->setCheckable(true);
  myGridAction->setChecked(true);
  myViewCubeAction = viewMenu->addAction(tr("View&Cube"));
  myViewCubeAction->setCheckable(true);
  myViewCubeAction->setChecked(true);

  QMenu* helpMenu = mb->addMenu(tr("&Help"));
  myAboutAction = helpMenu->addAction(tr("&About ClotCAD"));
}

void ViewerWindow::setupStatusBar()
{
  QStatusBar* sb = statusBar();
  myShapeCountLabel = new QLabel(tr("Displaying 0 shapes"));
  myFpsLabel = new QLabel(this);
  myImportStatusLabel = new QLabel(this);
  myImportStatusLabel->setStyleSheet("QLabel { color: #cc0000; text-decoration: underline; }");
  myImportStatusLabel->setCursor(Qt::PointingHandCursor);
  myImportStatusLabel->setVisible(false);
  myImportStatusLabel->installEventFilter(this);
  sb->addWidget(myShapeCountLabel);
  sb->addPermanentWidget(myImportStatusLabel);
  sb->addPermanentWidget(myFpsLabel);
}

void ViewerWindow::setupPanels()
{
  myRepl = new REPLPanel(this);
  addDockWidget(Qt::RightDockWidgetArea, myRepl);
  myRepl->setFeatures(QDockWidget::DockWidgetClosable | QDockWidget::DockWidgetMovable);
  connect(myReplAction, &QAction::toggled, myRepl, &QDockWidget::setVisible);
  myRepl->installEventFilter(this);

  mySceneTree = new SceneTreePanel(this);
  addDockWidget(Qt::LeftDockWidgetArea, mySceneTree);
  mySceneTree->setFeatures(QDockWidget::DockWidgetClosable | QDockWidget::DockWidgetMovable);
  connect(mySceneTreeAction, &QAction::toggled, mySceneTree, &QDockWidget::setVisible);
  mySceneTree->installEventFilter(this);
}

bool ViewerWindow::eventFilter(QObject* obj, QEvent* event)
{
  if (event->type() == QEvent::Show)
  {
    if (obj == myRepl)    myReplAction->setChecked(true);
    if (obj == mySceneTree) mySceneTreeAction->setChecked(true);
  }
  else if (event->type() == QEvent::Hide)
  {
    if (obj == myRepl)    myReplAction->setChecked(false);
    if (obj == mySceneTree) mySceneTreeAction->setChecked(false);
  }
  else if (event->type() == QEvent::MouseButtonPress && obj == myImportStatusLabel)
  {
    emit importCancelRequested();
    return true;
  }
  return QMainWindow::eventFilter(obj, event);
}

void ViewerWindow::setStatusText(const char* text)
{
  myShapeCountLabel->setText(QString::fromUtf8(text));
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
