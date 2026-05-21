#include "viewer_widget.h"
#include "occt_viewer.h"
#include "viewer_window.h"
#include "scene_tree_panel.h"
#include "OcctGlTools.h"
#include "OcctQtTools.h"

#include <AIS_DisplayMode.hxx>
#include <AIS_SelectionScheme.hxx>
#include <Aspect_DisplayConnection.hxx>
#include <OpenGl_GraphicDriver.hxx>
#include <OpenGl_Context.hxx>
#include <Quantity_Color.hxx>

#include <set>

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
}

void ViewerWidget::paintGL()
{
  if (myView.IsNull() || myView->Window().IsNull())
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

bool ViewerWidget::UpdateMouseClick(const NCollection_Vec2<int>& thePoint,
                                     Aspect_VKeyMouse theButton,
                                     Aspect_VKeyFlags theModifiers,
                                     bool theIsDoubleClick)
{
  if (theIsDoubleClick) return false;
  unsigned int key = (unsigned int)theButton | ((unsigned int)theModifiers << 16);
  AIS_SelectionScheme scheme = AIS_SelectionScheme_Replace;
  if (myViewerState)
  {
    auto it = myViewerState->mouse_schemes.find(key);
    if (it != myViewerState->mouse_schemes.end())
      scheme = (AIS_SelectionScheme)it->second;
  }
  SelectInViewer(thePoint, scheme);
  return true;
}

void ViewerWidget::OnSelectionChanged(const Handle(AIS_InteractiveContext)& theCtx,
                                       const Handle(V3d_View)&)
{
  if (!myViewerState) return;

  // Build set of selected shape names from OCCT context
  std::set<std::string> selected;
  for (theCtx->InitSelected(); theCtx->MoreSelected(); theCtx->NextSelected())
  {
    auto obj = theCtx->SelectedInteractive();
    auto it = myViewerState->obj_to_name.find(obj.get());
    if (it != myViewerState->obj_to_name.end())
      selected.insert(it->second);
  }

  // Sync scene tree selection (with blockSignals — prevents re-entrancy)
  auto docks = myViewerState->window->findChildren<SceneTreePanel*>();
  for (auto* dock : docks)
    dock->syncSelection(selected);

  // Fire Lisp callback
  if (myViewerState->selection_callback)
    myViewerState->selection_callback();
}

void ViewerWidget::updateView()
{
  update();
  emit viewRedrawn();
}
