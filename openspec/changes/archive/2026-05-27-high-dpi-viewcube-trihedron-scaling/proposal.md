## Why

On high-DPI (4K) displays, the ViewCube and axis trihedron appear physically too small — the ViewCube's text labels become unreadable because OCCT's font rendering doesn't scale with the device pixel ratio. Users with Retina-class monitors cannot read orientation labels, making the ViewCube useless.

## What Changes

- **C++**: Add 3 new C API functions: `viewer_set_viewcube_font_height`, `viewer_set_trihedron_font_size`, `viewer_get_device_pixel_ratio`. Each font-height/size setter multiplies the logical value by the widget's `devicePixelRatioF()` so callers always pass logical pixels.
- **C++ `viewer_create`**: Scale ViewCube size, font height, and corner offset by device pixel ratio at creation time.
- **C++ `viewer_show_axis`**: Scale trihedron size and corner offset by device pixel ratio at creation time.
- **Lisp bindings**: Add CFFI bindings for the 3 new C functions.
- **Lisp UI**: Add user-facing `set-viewcube-font-height` and `set-trihedron-font-size` functions for runtime theme control.
- **Lisp lifecycle**: Query device pixel ratio at startup and apply DPR-scaled defaults for both ViewCube and trihedron.
- **Lisp theme system**: Add `:viewcube-font-height` and `:trihedron-font-size` keys to both dark and light palette, applied during `apply-theme`.
- **Tests**: Add mock entries for the 3 new CFFI functions in the test framework.
- **Documentation**: Update `docs/clotcad-api.md` with the two new user-facing functions.

## Capabilities

### New Capabilities
- `high-dpi-viewcube-trihedron-scaling`: DPR-aware scaling of ViewCube and trihedron font sizes, geometry, and corner positioning for high-DPI displays, plus user-controllable font height/size for theming.

### Modified Capabilities

None — this is a new capability.

## Impact

- `wrap/occt_viewer.h` — 3 new C function declarations
- `wrap/occt_viewer.cpp` — 3 new function implementations + 2 modifications (viewer_create, viewer_show_axis)
- `src/viewer/bindings.lisp` — 3 new CFFI `defcfun` forms
- `src/viewer/ui.lisp` — 2 new user-facing functions
- `src/viewer/theme.lisp` — palette entries in both dark/light palettes, apply logic
- `src/viewer/lifecycle.lisp` — DPR-aware init in `initialize-viewer`
- `src/package.lisp` — exports for new symbols
- `t/viewer-tests.lisp` — 3 new mock entries
- `docs/clotcad-api.md` — documentation for new functions
