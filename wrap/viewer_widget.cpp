#include "viewer_widget.h"
#include "OcctGlTools.h"
#include "OcctQtTools.h"

#include <AIS_DisplayMode.hxx>
#include <AIS_Shape.hxx>
#include <AIS_Trihedron.hxx>
#include <Aspect_DisplayConnection.hxx>
#include <Geom_Axis2Placement.hxx>
#include <gp.hxx>
#include <Graphic3d_TransformPers.hxx>
#include <Graphic3d_TransModeFlags.hxx>
#include <Aspect_TypeOfTriedronPosition.hxx>
#include <OpenGl_GraphicDriver.hxx>
#include <OpenGl_Context.hxx>
#include <Prs3d_DatumMode.hxx>
#include <Quantity_Color.hxx>

ViewerWidget::ViewerWidget(QWidget* parent)
  : QOpenGLWidget(parent)
{
  Handle(Aspect_DisplayConnection) aDisp;
#if !defined(__APPLE__) && !defined(_WIN32) && !defined(HAVE_WAYLAND)
  aDisp = new Xw_DisplayConnection();
#endif
  Handle(OpenGl_GraphicDriver) aDriver = new OpenGl_GraphicDriver(aDisp, false);
  aDriver->ChangeOptions().buffersNoSwap = true;
  aDriver->ChangeOptions().buffersOpaqueAlpha = true;
  aDriver->ChangeOptions().useSystemBuffer = false;

  myViewer = new V3d_Viewer(aDriver);
  myViewer->SetDefaultBackgroundColor(Quantity_NOC_BLACK);
  myViewer->SetDefaultLights();
  myViewer->SetLightOn();

  myContext = new AIS_InteractiveContext(myViewer);
  myContext->SetDisplayMode(AIS_Shaded, false);

  myView = myViewer->CreateView();
  myView->SetImmediateUpdate(false);
  myView->ChangeRenderingParams().NbMsaaSamples = 4;
  myView->ChangeRenderingParams().IsAntialiasingEnabled = true;

  setMouseTracking(true);
  setFocusPolicy(Qt::StrongFocus);
  setUpdateBehavior(QOpenGLWidget::NoPartialUpdate);
}

ViewerWidget::~ViewerWidget()
{
  Handle(Aspect_DisplayConnection) aDisp = myViewer->Driver()->GetDisplayConnection();
  if (!myContext.IsNull())
    myContext->RemoveAll(false);
  myContext.Nullify();
  if (!myView.IsNull())
    myView->Remove();
  myView.Nullify();
  myViewer.Nullify();
  makeCurrent();
  aDisp.Nullify();
}

void ViewerWidget::initializeGL()
{
  OcctQtTools::qtGlCapsFromSurfaceFormat(
    Handle(OpenGl_GraphicDriver)::DownCast(myViewer->Driver())->ChangeOptions(),
    format());

  const Aspect_Drawable aNativeWin = (Aspect_Drawable)effectiveWinId();
  const NCollection_Vec2<int> aViewSize(width(), height());

  if (!OcctGlTools::InitializeGlWindow(myView, aNativeWin, aViewSize, devicePixelRatioF()))
  {
    qCritical("OpenGl_Context is unable to wrap OpenGL context");
    return;
  }
  makeCurrent();

  if (myFirstInit)
  {
    setupAxis();
    setupGrid();
    myFirstInit = false;
  }
}

void ViewerWidget::paintGL()
{
  if (myView.IsNull() || myView->Window().IsNull())
    return;

  // Skip rendering during modal file dialogs to avoid division-by-zero in OCCT
  if (myProcessingModal)
    return;

  OcctGlTools::InitializeGlFbo(myView);
  OcctGlTools::ResetGlStateBeforeOcct(myView);

  myView->Invalidate();
  myView->InvalidateImmediate();
  AIS_ViewController::FlushViewEvents(myContext, myView, true);

  OcctGlTools::ResetGlStateAfterOcct(myView);
}

void ViewerWidget::resizeGL(int /*w*/, int /*h*/)
{
  if (!myView.IsNull())
    myView->MustBeResized();
}

void ViewerWidget::mousePressEvent(QMouseEvent* event)
{
  if (!myView.IsNull() && !myView->Window().IsNull())
  {
    event->accept();
    if (OcctQtTools::qtHandleMouseEvent(*this, myView, event))
      updateView();
  }
  QOpenGLWidget::mousePressEvent(event);
}

void ViewerWidget::mouseReleaseEvent(QMouseEvent* event)
{
  if (!myView.IsNull() && !myView->Window().IsNull())
  {
    event->accept();
    if (OcctQtTools::qtHandleMouseEvent(*this, myView, event))
      updateView();
  }
  QOpenGLWidget::mouseReleaseEvent(event);
}

void ViewerWidget::mouseMoveEvent(QMouseEvent* event)
{
  if (!myView.IsNull() && !myView->Window().IsNull())
  {
    event->accept();
    if (OcctQtTools::qtHandleMouseEvent(*this, myView, event))
      updateView();
  }
  QOpenGLWidget::mouseMoveEvent(event);
}

void ViewerWidget::wheelEvent(QWheelEvent* event)
{
  if (!myView.IsNull() && !myView->Window().IsNull())
  {
    event->accept();
    if (OcctQtTools::qtHandleWheelEvent(*this, myView, event))
      updateView();
  }
  QOpenGLWidget::wheelEvent(event);
}

void ViewerWidget::handleViewRedraw(const Handle(AIS_InteractiveContext)& ctx,
                                    const Handle(V3d_View)& view)
{
  AIS_ViewController::handleViewRedraw(ctx, view);
  if (myToAskNextFrame)
    updateView();
}

void ViewerWidget::updateView()
{
  update();
  emit viewRedrawn();
}

void ViewerWidget::setupAxis()
{
  Handle(Geom_Axis2Placement) axes = new Geom_Axis2Placement(gp::Origin(), gp::DX(), gp::DY());
  myAxis = new AIS_Trihedron(axes);
  myAxis->SetDatumDisplayMode(Prs3d_DM_WireFrame);
  myAxis->SetDrawArrows(true);
  myAxis->SetSize(50.0);
  Handle(Graphic3d_TransformPers) tpers =
    new Graphic3d_TransformPers(Graphic3d_TMF_TriedronPers, Aspect_TOTP_LEFT_LOWER, NCollection_Vec2<int>(60, 60));
  myAxis->SetTransformPersistence(tpers);
  myContext->Display(myAxis, false);
  myContext->Deactivate(myAxis);
}

void ViewerWidget::setupGrid()
{
  myViewer->ActivateGrid(Aspect_GT_Rectangular, Aspect_GDM_Lines);
}
