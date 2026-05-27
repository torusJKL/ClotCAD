## Why

The viewer window always opens at a fixed 1024×768 size, which looks small and cramped on modern high-resolution displays. Users almost always maximize the window manually. Starting maximized by default provides a better out-of-box experience, while preserving the ability to set an explicit window size via command-line arguments for automated or testing scenarios.

## What Changes

- **ViewerWindow starts maximized** when no explicit `--width`/`--height` args are given
- **New CLI flags** `--width` and `--height` in `run.sh` for viewer mode only
- When `--width` and `--height` are provided, the window opens at that exact size (non-maximized)
- Headless modes (`--slynk`, `--alive`) are unaffected — no new flags
- New C function `viewer_set_window_state` to control the maximized flag
- Lisp `start-viewer` gains a `:maximized` keyword argument (default `t`)

## Capabilities

### New Capabilities
- `maximized-default`: Controls when the viewer window starts maximized, with CLI override support

### Modified Capabilities

No existing capability specs change at the requirement level — this is purely an implementation detail of window creation.

## Impact

- **C++**: `viewer_state.h` (new field), `occt_viewer.h/.cpp` (new function + `viewer_show` change), `viewer_window.h/.cpp` (no changes)
- **Lisp**: `bindings.lisp` (new CFFI binding), `lifecycle.lisp` (modified `start-viewer`)
- **Shell**: `scripts/run.sh` (new flags + pass-through to SBCL eval)
