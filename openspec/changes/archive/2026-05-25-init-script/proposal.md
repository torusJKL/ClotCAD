## Why

Users need a way to customize ClotCAD at startup — loading personal preferences, utility functions, or automation scripts — without manually evaluating forms each session. Currently there is no mechanism for automatic initialization.

## What Changes

- **Init file from `~/.config/clotcad/init.lisp`** — if the file exists, evaluate its forms form-by-form at viewer startup (before the main window event loop begins)
- **Command-line `--init FILE` argument** — specify a custom init file path; overrides the default config path. Works in both UI and headless (`--slynk`, `--alive`) modes
- **Command-line `--no-init` flag** — skip loading any init file, even if one exists at the default config path. Useful for troubleshooting
- **No init file** when the file doesn't exist and no `--init` flag is passed — no change in behavior for existing users

## Capabilities

### New Capabilities
- `init-script-loading`: Evaluate a Lisp init file form-by-form at ClotCAD startup, using the same evaluation mechanism as the import-lisp-file UI feature

### Modified Capabilities

- *(none)*

## Impact

- **Lisp**: `src/viewer/lifecycle.lisp` — add init-file loading logic to `bootstrap` and `start-viewer`; `src/viewer/repl.lisp` — possibly reuse `process-import-tick` or create a simpler synchronous equivalent
- **Shell**: `scripts/run.sh` — add `--init FILE` argument parsing; pass to `--eval` forms
- **C++**: `wrap/occt_viewer.cpp` — possibly no changes needed (init evaluation happens entirely in Lisp)
- **Distribution**: `scripts/package.sh`, `scripts/make-core.lisp` — no changes needed
