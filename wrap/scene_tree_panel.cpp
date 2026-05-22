#include "scene_tree_panel.h"
#include "occt_viewer.h"

SceneTreePanel::SceneTreePanel(QWidget* parent)
  : QDockWidget(tr("Scene Tree"), parent)
{
  setObjectName("SceneTreePanel");
  setFeatures(QDockWidget::DockWidgetClosable | QDockWidget::DockWidgetMovable);
  setMinimumWidth(150);
  setAllowedAreas(Qt::LeftDockWidgetArea | Qt::RightDockWidgetArea);

  myTree = new QTreeWidget(this);
  myTree->setHeaderHidden(true);
  myTree->setRootIsDecorated(false);
  myTree->setAnimated(true);
  myTree->setSelectionMode(QAbstractItemView::ExtendedSelection);

  setWidget(myTree);
  connect(myTree, &QTreeWidget::itemChanged, this, &SceneTreePanel::onItemChanged);
  connect(myTree, &QTreeWidget::itemSelectionChanged, this, &SceneTreePanel::onTreeSelectionChanged);
}

void SceneTreePanel::addShape(const QString& name)
{
  myTree->blockSignals(true);
  QTreeWidgetItem* item = new QTreeWidgetItem(myTree);
  item->setText(0, name);
  item->setFlags(item->flags() | Qt::ItemIsUserCheckable);
  item->setCheckState(0, Qt::Checked);
  myTree->blockSignals(false);
}

void SceneTreePanel::removeShape(const QString& name)
{
  for (int i = 0; i < myTree->topLevelItemCount(); ++i)
  {
    if (myTree->topLevelItem(i)->text(0) == name)
    {
      delete myTree->takeTopLevelItem(i);
      return;
    }
  }
}

void SceneTreePanel::clearAll()
{
  myTree->clear();
}

void SceneTreePanel::setShapeCheckState(const QString& name, bool checked)
{
  for (int i = 0; i < myTree->topLevelItemCount(); ++i)
  {
    QTreeWidgetItem* item = myTree->topLevelItem(i);
    if (item->text(0) == name)
    {
      myTree->blockSignals(true);
      item->setCheckState(0, checked ? Qt::Checked : Qt::Unchecked);
      myTree->blockSignals(false);
      return;
    }
  }
}

void SceneTreePanel::setShapeTreeVisible(const QString& name, bool visible)
{
  for (int i = 0; i < myTree->topLevelItemCount(); ++i)
  {
    QTreeWidgetItem* item = myTree->topLevelItem(i);
    if (item->text(0) == name)
    {
      item->setHidden(!visible);
      return;
    }
  }
}

void SceneTreePanel::syncSelection(const std::set<std::string>& selected)
{
  bool old = myTree->blockSignals(true);
  for (int i = 0; i < myTree->topLevelItemCount(); ++i)
  {
    QTreeWidgetItem* item = myTree->topLevelItem(i);
    item->setSelected(selected.count(item->text(0).toStdString()) > 0);
  }
  myTree->blockSignals(old);
}

void SceneTreePanel::onTreeSelectionChanged()
{
  if (!myViewerState || !myContext) return;

  // Clear OCCT selection and re-add based on current tree selection.
  // This runs on the main thread; direct OCCT context manipulation is safe.
  myContext->ClearSelected(false);
  auto items = myTree->selectedItems();
  for (auto* item : items)
  {
    auto it = myViewerState->shapes.find(item->text(0).toStdString());
    if (it != myViewerState->shapes.end())
      myContext->AddOrRemoveSelected(it->second, false);
  }
  myContext->HilightSelected(true);

  // Notify Lisp so *selected* stays in sync
  if (myViewerState->selection_callback)
    myViewerState->selection_callback();
}

void SceneTreePanel::onItemChanged(QTreeWidgetItem* item, int /*column*/)
{
  QString name = item->text(0);
  bool visible = item->checkState(0) == Qt::Checked;
  emit visibilityChanged(name, visible);
}
