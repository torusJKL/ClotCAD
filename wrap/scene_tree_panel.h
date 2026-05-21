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

#include <AIS_InteractiveContext.hxx>

class SceneTreePanel : public QDockWidget
{
  Q_OBJECT
public:
  SceneTreePanel(QWidget* parent = nullptr);

  void setContext(const Handle(AIS_InteractiveContext)& ctx) { myContext = ctx; }

signals:
  void visibilityChanged(const QString& name, bool visible);

public:
  void setShapeCheckState(const QString& name, bool checked);
  void setShapeTreeVisible(const QString& name, bool visible);

public slots:
  void addShape(const QString& name);
  void removeShape(const QString& name);
  void clearAll();

private slots:
  void onItemChanged(QTreeWidgetItem* item, int column);

private:
  QTreeWidget* myTree;
  Handle(AIS_InteractiveContext) myContext;
};

#endif
