#ifndef _OcctGlTools_HeaderFile
#define _OcctGlTools_HeaderFile

#include <Aspect_DisplayConnection.hxx>
#include <Aspect_NeutralWindow.hxx>
#include <NCollection_Vec2.hxx>
#include <V3d_View.hxx>

#if !defined(__APPLE__) && !defined(_WIN32) && defined(__has_include)
  #if __has_include(<Xw_DisplayConnection.hxx>)
    #include <Xw_DisplayConnection.hxx>
    #define USE_XW_DISPLAY
  #endif
#endif
#ifndef USE_XW_DISPLAY
typedef Aspect_DisplayConnection Xw_DisplayConnection;
#endif

class OpenGl_Context;
class OcctGlTools
{
public:
  class OcctNeutralWindow : public Aspect_NeutralWindow
  {
  public:
    OcctNeutralWindow() {}
    virtual double DevicePixelRatio() const override { return myPixelRatio; }
    void SetDevicePixelRatio(double theRatio) { myPixelRatio = theRatio; }
  private:
    double myPixelRatio = 1.0;
  };

public:
  static Handle(OpenGl_Context) GetGlContext(const Handle(V3d_View)& theView);
  static Aspect_Drawable GetGlNativeWindow(Aspect_Drawable theNativeWin);
  static bool InitializeGlWindow(const Handle(V3d_View)& theView,
                                 const Aspect_Drawable theNativeWin,
                                 const NCollection_Vec2<int>& theSize,
                                 const double thePixelRatio);
  static bool InitializeGlFbo(const Handle(V3d_View)& theView);
  static void ResetGlStateBeforeOcct(const Handle(V3d_View)& theView);
  static void ResetGlStateAfterOcct(const Handle(V3d_View)& theView);
};

#endif
