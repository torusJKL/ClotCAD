## Context

ClotCAD has no mechanism for user-level initialization at startup. Users who want custom key bindings, theme preferences, utility functions, or auto-loading packages must manually evaluate forms each session. The Lisp file import feature (File > Import Lisp) already provides form-by-form evaluation logic, but it's only accessible through the UI file dialog.

## Goals / Non-Goals

**Goals:**
- Load and evaluate an init Lisp file at startup, form-by-form
- Support a default config path: `~/.config/clotcad/init.lisp`
- Support a `--init FILE` CLI argument that overrides the default path
- Support a `--no-init` CLI flag to skip all init file loading
- Work in both UI (`--viewer`) and headless (`--slynk`, `--alive`) modes
- Reuse the existing `process-import-tick` evaluation machinery in UI mode
- No behavior change for users who don't have an init file

**Non-Goals:**
- Multiple init files (only one init file per session)
- Config file formats other than Lisp (no JSON, YAML, etc.)
- Hot-reloading the init file after startup
- Persisting state from the init file to the config directory (no auto-save)

## Decisions

1. **Reuse `process-import-tick` for UI mode** — The existing form-by-form evaluator in `repl.lisp` already handles sequential evaluation, REPL output display, error handling, and import progress tracking. Populating `*import-forms*` with the init file content and posting a wake event triggers the same pipeline. No new evaluation code needed.

2. **Synchronous evaluation for headless mode** — In `--slynk` and `--alive` modes there is no viewer, no REPL panel, and no event queue. The init file is evaluated with a simple `(dolist (form forms) (eval form))` inside a `progn` passed to `--eval`. This avoids depending on viewer infrastructure.

3. **`*init-file-path*` special variable** — Rather than threading an init-file parameter through all startup paths, use a dynamic variable. `run.sh` sets it via `--eval` before the startup commands. `start-viewer` and headless paths read it to decide what to load.

4. **Default path resolution in Lisp** — The default path `~/.config/clotcad/init.lisp` is resolved in Lisp using `(merge-pathnames ".config/clotcad/init.lisp" (user-homedir-pathname))`. This avoids shell-level path resolution complications.

5. **`--init` replaces default, does not add** — If `--init` is specified, the default `~/.config/clotcad/init.lisp` is skipped entirely. This keeps behavior predictable: exactly one init file or none.

6. **`--no-init` flag** — When `--no-init` is passed, no init file is loaded regardless of whether the default path exists or `--init` was also given. This is a pure override for troubleshooting or CI environments where init file side effects are unwanted.

7. **Bind `*package*` to `clotcad-user` during read and eval** — Symbols are interned at READ time, not eval time. Both `load-init-file-headless` and `load-init-file-ui` must bind `*package*` around the `with-open-file` / `read` loop so that symbols like `apply-theme`, `display`, `make-box` are interned in `clotcad-user` from the start. `process-import-tick` also binds `*package*` around eval as a safety net for forms read in the wrong package (e.g., the existing File > Import Lisp path).

8. **No changes to C++** — All init-file logic is pure Lisp. The C++ library is not involved.

## Risks / Trade-offs

- **Init file blocks startup in headless mode** — If the init file contains long-running computations, headless mode startup is delayed. Mitigation: this is expected behavior (the user explicitly asked for it).
- **Init file errors in UI mode** — An error in one form does not abort the entire init file (same behavior as File > Import Lisp). The remaining forms continue evaluation. This is handled by the existing `handler-case` in `process-import-tick`.
- **Init file in `--init` with absolute path loads before Qt init** — The init file is loaded after the Lisp process starts but before viewer/headless mode. The `clotcad-user` package is available but Qt/OCCT may not be initialized yet. Users should not rely on OCCT state in the init file. This is documented behavior.
