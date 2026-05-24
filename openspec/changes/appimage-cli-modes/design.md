## Context

ClotCAD currently has a single entry point: `(clotcad:bootstrap)` which starts the Qt viewer, Slynk (port 4005), and Alive LSP (port 4006) together. The viewer blocks forever on `QApplication::exec()`. There is no way to:

- Start only Slynk without the viewer (for headless/AI use)
- Start only Alive LSP without the viewer

The AppImage entry point (`AppRun` = `scripts/run.sh`) is a bash script that currently hardcodes the `bootstrap` call and ignores all CLI args.

## Goals / Non-Goals

**Goals:**
- Provide `--slynk` and `--alive` headless modes (no viewer, no DISPLAY required when `QT_QPA_PLATFORM=offscreen`)
- Route all modes through a single AppImage with consistent `-p`/`-a` flag conventions
- Refactor Lisp code cleanly — extract reusable startups, add `wait-forever`

**Non-Goals:**
- HTTP or RPC layer — raw SLY protocol over TCP is sufficient
- Strict sandboxing or eval restrictions — the Slynk server already has full Lisp access; nothing new
- Windows/macOS support — AppImage is Linux-only; no changes to platform targeting

## Decisions

### 1. Headless mode process model

Without the Qt event loop, the main thread would exit immediately after starting Slynk/Alive threads. A `wait-forever` function keeps the process alive:

```
(defun wait-forever ()
  (handler-case (loop (sleep 1))
    (sb-sys:interactive-interrupt () (sb-ext:exit))
    (sb-sys:terminate-interrupt () (sb-ext:exit))))
```

`(loop (sleep 1))` is not a busy wait — `sleep` yields the OS timeslice, zero CPU usage. The handler-case catches Ctrl+C/Ctrl+Break and exits cleanly without entering the debugger.

### 2. AppRun routing architecture

The bash `AppRun` uses a `case` on `$1`, shifts, and parses flags with a simple `while` loop before constructing the appropriate `--eval` string for `sbcl`. No arg-parsing libraries needed — the flag set is small and fixed.

Default mode (no args or `--viewer`) preserves backward compatibility — existing users who double-click or run bare `./ClotCAD.AppImage` get the full viewer.

### 3. Port flag conventions

```
--viewer  (default)    -p <slynk-port:4005>   -a <alive-port:4006>
--slynk                -p <slynk-port:4005>
--alive                -a <alive-port:4006>
```

`-a` always sets the Alive LSP port, `-p` always sets the "primary" port for that mode (Slynk for `--viewer`/`--slynk`, Alive for `--alive`). This avoids confusion.

### 4. Headless Qt safety

Loading `libclotcad.so` links Qt6 even in headless mode. On a system without `$DISPLAY`, Qt's platform plugins will fail. The fix: set `QT_QPA_PLATFORM=offscreen` in the `--slynk`/`--alive` AppRun branches. This tells Qt to use the offscreen platform plugin instead of XCB/Wayland.

If the offscreen platform plugin is unavailable (not bundled), this will fail. Mitigation: bundle `libqoffscreen.so` in the AppImage, or accept that headless modes require a display or `QT_QPA_PLATFORM=offscreen` with the plugin installed on the host.

## Risks / Trade-offs

- **[Qt in headless mode]** The headless modes still link Qt6 via `libclotcad.so`. If Qt cannot initialize (no DISPLAY, no offscreen plugin), the process will crash. Mitigation: bundle the offscreen platform plugin, document `QT_QPA_PLATFORM=offscreen`.
