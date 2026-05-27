## 1. C++: New API functions + DPR scaling at creation

- [x] 1.1 Add `viewer_set_viewcube_font_height` declaration in `wrap/occt_viewer.h`
- [x] 1.2 Add `viewer_set_trihedron_font_size` declaration in `wrap/occt_viewer.h`
- [x] 1.3 Add `viewer_get_device_pixel_ratio` declaration in `wrap/occt_viewer.h`
- [x] 1.4 Implement `viewer_set_viewcube_font_height` in `wrap/occt_viewer.cpp` (DPR-multiplying)
- [x] 1.5 Implement `viewer_set_trihedron_font_size` in `wrap/occt_viewer.cpp` (iterate X/Y/Z datum parts, DPR-multiplying)
- [x] 1.6 Implement `viewer_get_device_pixel_ratio` in `wrap/occt_viewer.cpp`
- [x] 1.7 Modify `viewer_create` to scale ViewCube size, font height, and corner offset by DPR
- [x] 1.8 Modify `viewer_show_axis` to scale trihedron size and corner offset by DPR

## 2. Lisp: CFFI bindings

- [x] 2.1 Add `%viewer-set-viewcube-font-height` binding in `src/viewer/bindings.lisp`
- [x] 2.2 Add `%viewer-set-trihedron-font-size` binding in `src/viewer/bindings.lisp`
- [x] 2.3 Add `%viewer-get-device-pixel-ratio` binding in `src/viewer/bindings.lisp`
- [x] 2.4 Export new % symbols from `:clotcad.impl` in `src/package.lisp`

## 3. Lisp: User-facing functions + lifecycle

- [x] 3.1 Add `set-viewcube-font-height` function in `src/viewer/ui.lisp`
- [x] 3.2 Add `set-trihedron-font-size` function in `src/viewer/ui.lisp`
- [x] 3.3 Export new user-facing symbols from `:clotcad` in `src/package.lisp`
- [x] 3.4 Add DPR-aware initialization in `initialize-viewer` in `src/viewer/lifecycle.lisp` (scale ViewCube size, font height, trihedron font size using `%viewer-get-device-pixel-ratio`)

## 4. Lisp: Theme system integration

- [x] 4.1 Add `:viewcube-font-height` to `%dark-palette` and `%light-palette`
- [x] 4.2 Add `:trihedron-font-size` to `%dark-palette` and `%light-palette`
- [x] 4.3 Add font height application in `%apply-viewcube-colors`
- [x] 4.4 Add font size application in `%apply-axis-colors`

## 5. Tests

- [x] 5.1 Add mock entries for `%viewer-set-viewcube-font-height`, `%viewer-set-trihedron-font-size`, `%viewer-get-device-pixel-ratio` in `t/viewer-tests.lisp` mock list
- [x] 5.2 Add mock entries in the restore-block sections of test helpers

## 6. Documentation

- [x] 6.1 Add `set-viewcube-font-height` and `set-trihedron-font-size` to `docs/clotcad-api.md` under View Controls

## 7. Build and verify

- [x] 7.1 Build `libclotcad.so` with `just viewer`
- [x] 7.2 Run test suite with `just test`
