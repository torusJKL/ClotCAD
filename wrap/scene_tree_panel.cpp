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

bool removeChildRecursive(QTreeWidgetItem* parent, const QString& name)
{
  for (int i = 0; i < parent->childCount(); ++i)
  {
    QTreeWidgetItem* child = parent->child(i);
    if (child->text(0) == name)
    {
      delete parent->takeChild(i);
      return true;
    }
    if (removeChildRecursive(child, name))
      return true;
  }
  return false;
}

void SceneTreePanel::removeShape(const QString& name)
{
  for (int i = 0; i < myTree->topLevelItemCount(); ++i)
  {
    QTreeWidgetItem* item = myTree->topLevelItem(i);
    if (item->text(0) == name)
    {
      delete myTree->takeTopLevelItem(i);
      return;
    }
    if (removeChildRecursive(item, name))
      return;
  }
}

void SceneTreePanel::clearAll()
{
  myTree->clear();
}

QTreeWidgetItem* findItemRecursive(QTreeWidgetItem* parent, const QString& name)
{
  if (parent->text(0) == name)
    return parent;
  for (int i = 0; i < parent->childCount(); ++i)
  {
    QTreeWidgetItem* found = findItemRecursive(parent->child(i), name);
    if (found)
      return found;
  }
  return nullptr;
}

void SceneTreePanel::setShapeCheckState(const QString& name, bool checked)
{
  for (int i = 0; i < myTree->topLevelItemCount(); ++i)
  {
    QTreeWidgetItem* item = myTree->topLevelItem(i);
    QTreeWidgetItem* found = findItemRecursive(item, name);
    if (found)
    {
      myTree->blockSignals(true);
      found->setCheckState(0, checked ? Qt::Checked : Qt::Unchecked);
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
    QTreeWidgetItem* found = findItemRecursive(item, name);
    if (found)
    {
      found->setHidden(!visible);
      return;
    }
  }
}

void SceneTreePanel::addChildShape(const QString& parentName, const QString& childName)
{
  for (int i = 0; i < myTree->topLevelItemCount(); ++i)
  {
    QTreeWidgetItem* parent = myTree->topLevelItem(i);
    if (parent->text(0) == parentName)
    {
      myTree->blockSignals(true);
      QTreeWidgetItem* child = new QTreeWidgetItem(parent);
      child->setText(0, childName);
      child->setFlags(child->flags() | Qt::ItemIsUserCheckable);
      child->setCheckState(0, Qt::Checked);
      parent->setExpanded(true);
      myTree->blockSignals(false);
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
