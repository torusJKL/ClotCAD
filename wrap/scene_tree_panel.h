#ifndef SCENE_TREE_PANEL_H
#define SCENE_TREE_PANEL_H

#include <Standard_WarningsDisable.hxx>
#include <QDockWidget>
#include <QTreeWidget>
#include <QTreeWidgetItem>
#include <QVBoxLayout>
#include <QHeaderView>
#include <QString>
#include <Standard_WarningsRestore.hxx>

#include "viewer_state.h"

#include <AIS_InteractiveContext.hxx>
#include <set>
#include <string>

class SceneTreePanel : public QDockWidget
{
  Q_OBJECT
public:
  SceneTreePanel(QWidget* parent = nullptr);

  void setViewerState(ViewerState* state) { myViewerState = state; }
  void setContext(const Handle(AIS_InteractiveContext)& ctx) { myContext = ctx; }

  void syncSelection(const std::set<std::string>& selected);

signals:
  void visibilityChanged(const QString& name, bool visible);

public:
  void setShapeCheckState(const QString& name, bool checked);
  void setShapeTreeVisible(const QString& name, bool visible);
  void addChildShape(const QString& parentName, const QString& childName);

public slots:
  void addShape(const QString& name);
  void removeShape(const QString& name);
  void clearAll();

private slots:
  void onItemChanged(QTreeWidgetItem* item, int column);
  void onTreeSelectionChanged();

private:
  QTreeWidget* myTree;
  Handle(AIS_InteractiveContext) myContext;
  ViewerState* myViewerState = nullptr;
};

#endif
