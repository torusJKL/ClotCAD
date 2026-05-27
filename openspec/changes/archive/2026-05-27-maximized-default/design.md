## Context

The viewer window is created via a C API chain: Lisp `start-viewer` → CFFI `%viewer-create` → C `viewer_create(title, width, height)` → `ViewerWindow` constructor → `resize(width, height)`. The default size of 1024×768 hasn't changed since the project began. Distribution users run via `scripts/run.sh` which calls `sbcl --eval "(clotcad:start-viewer)"` with no size arguments.

Headless modes (`--slynk`, `--alive`) set `QT_QPA_PLATFORM=offscreen` and never call `start-viewer`, so they are naturally unaffected.

## Goals / Non-Goals

**Goals:**
- Viewer window starts maximized when launched without explicit dimensions
- User can pass `--width W --height H` to `run.sh` to override with a fixed size
- Fixed-size windows are NOT maximized
- Zero behavior change for headless modes
- All changes backward compatible — existing Lisp API (`start-viewer :width W :height H`) continues to work

**Non-Goals:**
- No GUI toggle or menu option for maximize (future concern)
- No remember-last-size persistence
- No changes to `ViewerWindow` class hierarchy or constructor signature

## Decisions

1. **State flag over constructor param**: A new `int maximized` field on `ViewerState` is set via C function `viewer_set_window_state()` after `viewer_create()` but before `viewer_show()`. This avoids changing the `viewer_create` C signature (which would break the CFFI binding) and keeps the Lisp-side control clean.

2. **`showMaximized()` in `viewer_show`**: Instead of modifying the `ViewerWindow` constructor, `viewer_show` checks `s->maximized` and calls either `showMaximized()` or `show()`. This is the minimal touchpoint — Qt's `showMaximized()` handles all platform quirks (WM decoration, taskbar, etc.).

3. **Lisp `:maximized` keyword on `start-viewer`**: Defaults to `t`. When `:maximized` is `t` and no `:width`/`:height` are explicitly provided, the viewer starts maximized. If the caller provides `:width`/`:height`, they can also pass `:maximized nil` (or omit it for size-then-maximize behavior, though the CLI path always passes `nil`).

4. **`run.sh` flag handling**: `--width` and `--height` are only parsed in viewer mode. When both are present, `run.sh` passes them to SBCL as `(clotcad:start-viewer :width W :height H)`. When absent, `(clotcad:start-viewer)` is used (which defaults to maximized).

5. **No spec file needed**: The change is purely an internal implementation detail of window creation. No existing spec has behavior-level requirements that change.

## Risks / Trade-offs

- **Virtual machine / remote desktop**: `showMaximized()` may behave differently across window managers. Fallback: user can always use `--width 1024 --height 768` to get the old behavior.
- **Race with init scripts**: Init scripts run asynchronously in viewer mode (via `load-init-file-ui`), so no timing issue.
- **SBCL core dump**: The `just core` command builds `ClotCAD.core` which contains `start-viewer`. No ABI changes since `viewer_create` signature is unchanged.
