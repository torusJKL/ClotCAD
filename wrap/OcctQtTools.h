#ifndef _OcctQtTools_HeaderFile
#define _OcctQtTools_HeaderFile

#include <Aspect_VKey.hxx>
#include <Aspect_VKeyFlags.hxx>
#include <Aspect_WindowInputListener.hxx>
#include <NCollection_Vec2.hxx>
#include <V3d_View.hxx>

#include <Standard_WarningsDisable.hxx>
#include <QSurfaceFormat>
#include <QMouseEvent>
#include <QWheelEvent>
#include <QKeyEvent>
#include <Standard_WarningsRestore.hxx>

class OpenGl_Caps;

class OcctQtTools
{
public:
  static void qtGlPlatformSetup();
  static QSurfaceFormat qtGlSurfaceFormat();
  static void qtGlCapsFromSurfaceFormat(OpenGl_Caps& theCaps, const QSurfaceFormat& theFormat);
  static bool qtHandleMouseEvent(Aspect_WindowInputListener& theListener,
                                 const Handle(V3d_View)& theView,
                                 const QMouseEvent* theEvent);
  static bool qtHandleWheelEvent(Aspect_WindowInputListener& theListener,
                                 const Handle(V3d_View)& theView,
                                 const QWheelEvent* theEvent);
  static Aspect_VKeyMouse qtMouseButtons2VKeys(Qt::MouseButtons theButtons);
  static Aspect_VKeyFlags qtMouseModifiers2VKeys(Qt::KeyboardModifiers theModifiers);
  static Aspect_VKey qtKey2VKey(int theKey);
};

#endif
