## Why

The 3D viewport lacks a visual orientation aid — users must orbit to understand the current viewpoint. Adding an AIS_ViewCube provides intuitive one-click view switching (front, top, left, etc.), bringing the viewer in line with modern CAD applications. Bidirectional Lisp control enables programmatic camera manipulation and scripting.

## What Changes

- **Add**: AIS_ViewCube displayed in the top-right corner of the viewport with transform persistence
- **Add**: View menu toggle for ViewCube visibility (checkable, like Axis/Grid)
- **Add**: Click-to-orient — clicking any cube face/edge/vertex smoothly animates the camera to that view
- **Add**: Lisp API for programmatic view control: `(set-view :top)`, `(current-view)`, `(show-viewcube ...)`, `(toggle-viewcube)`
- **Add**: Bidirectional view sync — ViewCube clicks fire a Lisp callback updating `*current-view*`; Lisp `set-view` updates the ViewCube display
- **Add**: ViewCube theming — color, text color, transparency, size configurable via palette alongside trihedron colors

## Capabilities

### New Capabilities
- `viewcube-core`: C++ side — AIS_ViewCube creation, visibility toggle, programmatic view set/get (via V3d_View::SetProj), ViewCube-to-Lisp callback, theming API functions
- `viewcube-lisp`: Lisp side — CFFI bindings for viewcube operations, high-level functions (set-view, current-view, show-viewcube, toggle-viewcube), *current-view* state variable, theme palette integration

### Modified Capabilities

None.

## Impact

- **C++**: Add `AIS_ViewCube` header include to `occt_viewer.cpp`. Add `Handle(AIS_ViewCube) viewCube` to `ViewerState`. Add ~8 new C API functions: `viewer_show_viewcube`, `viewer_is_viewcube_visible`, `viewer_set_view`, `viewer_get_view_orientation`, `viewer_set_viewcube_color`, `viewer_set_viewcube_text_color`, `viewer_set_viewcube_size`, `viewer_set_viewcube_callback`. Override `onAnimationFinished()` on the ViewCube to fire the orientation callback.
- **Lisp**: Add CFFI bindings in `bindings.lisp`. Add state var `*current-view*` in `ui.lisp`. Add `set-view`, `current-view`, `show-viewcube`, `toggle-viewcube` functions. Add theme palette entries for viewcube colors in `theme.lisp`. Register callback in `register-viewer-callbacks`.
- **Dependencies**: None — AIS_ViewCube is part of OCCT TKV3d (already linked).
