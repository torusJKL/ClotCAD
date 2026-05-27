## 1. C++ — Viewer state and window control

- [x] 1.1 Add `int maximized` field (default `0`) to `ViewerState` in `wrap/viewer_state.h`
- [x] 1.2 Add `viewer_set_window_state(occt_viewer vwr, int maximized)` to `wrap/occt_viewer.h` and `wrap/occt_viewer.cpp` — sets `s->maximized`
- [x] 1.3 Modify `viewer_show` in `wrap/occt_viewer.cpp`: when `s->maximized`, call `s->window->showMaximized()` instead of `s->window->show()`

## 2. Lisp — CFFI binding and lifecycle update

- [x] 2.1 Add `(%viewer-set-window-state "viewer_set_window_state")` CFFI binding in `src/viewer/bindings.lisp` (`:void` return, `(vwr :pointer) (maximized :int)`)
- [x] 2.2 Add `%viewer-set-window-state` to the export list in `src/package.lisp` (both `:clotcad.impl` and `:clotcad` packages)
- [x] 2.3 Modify `start-viewer` in `src/viewer/lifecycle.lisp` — add `(maximized t)` keyword, call `%viewer-set-window-state vwr (if maximized 1 0)` before `%viewer-show`

## 3. Shell — CLI flags and pass-through

- [x] 3.1 Add `--width W` and `--height H` options to `scripts/run.sh`: parse in viewer mode only, show usage error in headless modes
- [x] 3.2 Modify viewer-mode `sbcl` invocation in `scripts/run.sh`: when `--width`/`--height` provided, pass `(clotcad:start-viewer :maximized nil :width W :height H)`; otherwise pass `(clotcad:start-viewer)`
- [x] 3.3 Update `run.sh` usage text and examples to document `--width`/`--height`

## 4. Tests

- [x] 4.1 Add `%viewer-set-window-state` to the mocked CFFI list in `t/viewer-tests.lisp` (the `with-mocked-viewer` macro)
- [x] 4.2 Add test: `set-initial-window-state` with t calls `%viewer-set-window-state` with `1`
- [x] 4.3 Add test: `set-initial-window-state` with nil calls `%viewer-set-window-state` with `0`

## 5. Build and verify

- [x] 5.1 Build `lib/libclotcad.so` with `just viewer` — no compilation errors
- [x] 5.2 Run `just test` — 187/187 pass
- [x] 5.3 Launch viewer and verify it opens maximized
- [x] 5.4 Launch with `--width 1024 --height 768` and verify 1024×768 non-maximized
