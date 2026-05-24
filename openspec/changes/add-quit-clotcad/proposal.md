## Why

Currently there is no way to gracefully shut down a ClotCAD instance from a remote SLY or Alive LSP client. Headless modes (`--slynk`, `--alive`) block indefinitely in `wait-forever` and can only be stopped via SIGINT. GUI mode (`--viewer`) requires the window close button. Users connecting remotely have no way to programmatically end their session or restart services.

## What Changes

- Add `(quit-clotcad)` function that stops all services (viewer, Slynk, Alive LSP) and exits the Lisp process cleanly
- Fix latent rename artifact bug: `"CL-OCCT-USER"` → `"CLOTCAD-USER"` in Alive LSP default-package parameter
- Export `quit-clotcad` from the `:clotcad` and `:clotcad.impl` packages
- Update README with documentation and examples for the new function
- No breaking changes — existing APIs remain unchanged

## Capabilities

### New Capabilities
- `remote-shutdown`: Graceful shutdown of all ClotCAD services triggered from a remote SLY or Alive LSP client. Supports both headless and GUI modes.

### Modified Capabilities

None.

## Impact

- `src/viewer/lifecycle.lisp` — add `quit-clotcad` function; fix package name string
- `src/package.lisp` — export new `quit-clotcad` symbol in `:clotcad.impl` and `:clotcad`
- `README.md` — document `quit-clotcad` usage
- `t/viewer-tests.lisp` — add existence/functionality test for `quit-clotcad`
