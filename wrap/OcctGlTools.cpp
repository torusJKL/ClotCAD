#include "OcctGlTools.h"

#include <OpenGl_GraphicDriver.hxx>
#include <OpenGl_GlCore20.hxx>
#include <OpenGl_FrameBuffer.hxx>
#include <OpenGl_View.hxx>
#include <OpenGl_Window.hxx>
#include <Message.hxx>
#include <NCollection_Vec2.hxx>

class OcctQtFrameBuffer : public OpenGl_FrameBuffer
{
  DEFINE_STANDARD_RTTI_INLINE(OcctQtFrameBuffer, OpenGl_FrameBuffer)
public:
  OcctQtFrameBuffer() {}
  virtual void BindBuffer(const Handle(OpenGl_Context)& theGlCtx) override
  {
    OpenGl_FrameBuffer::BindBuffer(theGlCtx);
    theGlCtx->SetFrameBufferSRGB(true, false);
  }
  virtual void BindDrawBuffer(const Handle(OpenGl_Context)& theGlCtx) override
  {
    OpenGl_FrameBuffer::BindDrawBuffer(theGlCtx);
    theGlCtx->SetFrameBufferSRGB(true, false);
  }
  virtual void BindReadBuffer(const Handle(OpenGl_Context)& theGlCtx) override
  {
    OpenGl_FrameBuffer::BindReadBuffer(theGlCtx);
  }
};

Handle(OpenGl_Context) OcctGlTools::GetGlContext(const Handle(V3d_View)& theView)
{
  Handle(OpenGl_View) aGlView = Handle(OpenGl_View)::DownCast(theView->View());
  return aGlView->GlWindow()->GetGlContext();
}

Aspect_Drawable OcctGlTools::GetGlNativeWindow(Aspect_Drawable theNativeWin)
{
  Aspect_Drawable aNativeWin = (Aspect_Drawable)theNativeWin;
  return aNativeWin;
}

bool OcctGlTools::InitializeGlWindow(const Handle(V3d_View)& theView,
                                     const Aspect_Drawable theNativeWin,
                                     const NCollection_Vec2<int>& theSize,
                                     const double thePixelRatio)
{
  const Aspect_Drawable aNativeWin = GetGlNativeWindow(theNativeWin);
  Handle(OpenGl_GraphicDriver) aDriver = Handle(OpenGl_GraphicDriver)::DownCast(theView->Viewer()->Driver());
  Handle(OpenGl_Context) aGlCtx = new OpenGl_Context();
  if (!aGlCtx->Init(!aDriver->Options().contextCompatible))
  {
    Message::SendFail() << "Error: OpenGl_Context is unable to wrap OpenGL context";
    return false;
  }
  Handle(OcctNeutralWindow) aWindow = Handle(OcctNeutralWindow)::DownCast(theView->Window());
  if (aWindow.IsNull())
  {
    aWindow = new OcctNeutralWindow();
    aWindow->SetVirtual(true);
  }
  aWindow->SetNativeHandle(aNativeWin);
  aWindow->SetSize(theSize.x(), theSize.y());
  aWindow->SetDevicePixelRatio(thePixelRatio);
  theView->SetWindow(aWindow, aGlCtx->RenderingContext());
  theView->MustBeResized();
  theView->Invalidate();
  return true;
}

bool OcctGlTools::InitializeGlFbo(const Handle(V3d_View)& theView)
{
  Handle(OpenGl_Context) aGlCtx = OcctGlTools::GetGlContext(theView);
  Handle(OcctQtFrameBuffer) aDefaultFbo = Handle(OcctQtFrameBuffer)::DownCast(aGlCtx->DefaultFrameBuffer());
  if (aDefaultFbo.IsNull())
    aDefaultFbo = new OcctQtFrameBuffer();
  if (!aDefaultFbo->InitWrapper(aGlCtx))
  {
    aDefaultFbo.Nullify();
    Message::DefaultMessenger()->Send("Default FBO wrapper creation failed", Message_Fail);
    return false;
  }
  aGlCtx->SetDefaultFrameBuffer(Handle(OpenGl_FrameBuffer)());
  NCollection_Vec2<int> aViewSizeOld;
  const NCollection_Vec2<int> aViewSizeNew = aDefaultFbo->GetVPSize();
  Handle(OcctNeutralWindow) aWindow = Handle(OcctNeutralWindow)::DownCast(theView->Window());
  aWindow->Size(aViewSizeOld.x(), aViewSizeOld.y());
  if (aViewSizeNew != aViewSizeOld)
  {
    aWindow->SetSize(aViewSizeNew.x(), aViewSizeNew.y());
    theView->MustBeResized();
    theView->Invalidate();
  }
  aGlCtx->SetDefaultFrameBuffer(aDefaultFbo);
  return true;
}

void OcctGlTools::ResetGlStateBeforeOcct(const Handle(V3d_View)& theView)
{
  Handle(OpenGl_Context) aGlCtx = GetGlContext(theView);
  if (aGlCtx.IsNull())
    return;
  if (aGlCtx->core20fwd != nullptr)
    aGlCtx->core20fwd->glUseProgram(0);
  aGlCtx->core11fwd->glBindTexture(GL_TEXTURE_2D, 0);
  aGlCtx->core11fwd->glDisable(GL_BLEND);
  if (aGlCtx->core11ffp != nullptr)
  {
    aGlCtx->core11fwd->glDisable(GL_ALPHA_TEST);
    aGlCtx->core11fwd->glDisable(GL_TEXTURE_2D);
  }
}

void OcctGlTools::ResetGlStateAfterOcct(const Handle(V3d_View)& theView)
{
  Handle(OpenGl_Context) aGlCtx = GetGlContext(theView);
  if (aGlCtx.IsNull())
    return;
  aGlCtx->core11fwd->glPixelStorei(GL_PACK_ALIGNMENT, 4);
  aGlCtx->core11fwd->glPixelStorei(GL_UNPACK_ALIGNMENT, 4);
  if (aGlCtx->core15fwd != nullptr)
    aGlCtx->core15fwd->glActiveTexture(GL_TEXTURE0);
}
