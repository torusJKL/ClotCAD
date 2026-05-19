#ifndef VIEWER_WIDGET_H
#define VIEWER_WIDGET_H

#include <AIS_InteractiveContext.hxx>
#include <AIS_Trihedron.hxx>
#include <AIS_ViewController.hxx>
#include <V3d_Viewer.hxx>
#include <V3d_View.hxx>

#include <Standard_WarningsDisable.hxx>
#include <QOpenGLWidget>
#include <QMouseEvent>
#include <QWheelEvent>
#include <Standard_WarningsRestore.hxx>

class ViewerWidget : public QOpenGLWidget, public AIS_ViewController
{
  Q_OBJECT
public:
  ViewerWidget(QWidget* parent = nullptr);
  ~ViewerWidget();

  const Handle(V3d_Viewer)& Viewer() const { return myViewer; }
  const Handle(V3d_View)& View() const { return myView; }
  const Handle(AIS_InteractiveContext)& Context() const { return myContext; }

signals:
  void viewRedrawn();

protected:
  void initializeGL() override;
  void paintGL() override;
  void resizeGL(int w, int h) override;

  void mousePressEvent(QMouseEvent* event) override;
  void mouseReleaseEvent(QMouseEvent* event) override;
  void mouseMoveEvent(QMouseEvent* event) override;
  void wheelEvent(QWheelEvent* event) override;

  void handleViewRedraw(const Handle(AIS_InteractiveContext)& ctx,
                        const Handle(V3d_View)& view) override;

private:
  void updateView();
  void setupAxis();
  void setupGrid();

  Handle(V3d_Viewer) myViewer;
  Handle(V3d_View) myView;
  Handle(AIS_InteractiveContext) myContext;
  Handle(AIS_Trihedron) myAxis;
  bool myFirstInit = true;
};

#endif
