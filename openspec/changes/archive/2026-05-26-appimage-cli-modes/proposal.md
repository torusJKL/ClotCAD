## Why

Headless server modes make ClotCAD usable in CI pipelines and automated workflows where no display is available. Currently Slynk and Alive LSP always start together with the Qt viewer, and there is no way to run them independently.

## What Changes

- **Headless Slynk mode** (`--slynk`): Start ClotCAD without the viewer — just the Slynk server on port 4005. Process stays alive, accepts connections.
- **Headless Alive LSP mode** (`--alive`): Start ClotCAD without the viewer — just the Alive LSP server on port 4006. Process stays alive.
- **Optional port flags** (`-p`/`-a`): All modes accept `-p <port>` (and `--viewer` also accepts `-a <alive-port>`) to override default ports.
- **AppRun routing**: The `AppRun` entry point parses the first argument as a mode (`--slynk`, `--alive`, `--viewer`), consumes flags, and dispatches to the right entry point.
- **Lisp refactor**: Extract `start-slynk` and `start-alive` from `bootstrap` into standalone functions. Add `wait-forever` with signal handling.

## Capabilities

### New Capabilities
- `headless-modes`: Ability to start ClotCAD in headless mode (Slynk-only or Alive LSP-only) without the Qt viewer GUI, with configurable ports.
- `appimage-routing`: CLI argument parsing in the AppImage AppRun entry point to dispatch to viewer or headless modes with consistent flag conventions.

### Modified Capabilities

None — no existing specs to modify.

## Impact

- **`src/viewer/lifecycle.lisp`**: Refactor Slynk/Alive startup out of `bootstrap` into separate functions. Add `wait-forever`.
- **`scripts/run.sh`**: Rewrite of the routing logic to dispatch on mode argument.
- **`scripts/make-core.lisp`**: Ensure the new `wait-forever` function is included in the core dump.
- **`justfile`**: No changes needed (existing build commands remain valid).
