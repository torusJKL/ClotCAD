## 1. Add init-file loading infrastructure in Lisp

- [x] 1.1 Add `*init-file-path*` dynamic variable to `repl.lisp` — stores the path to the init file, set by CLI argument or defaulted to `~/.config/clotcad/init.lisp`
- [x] 1.2 Add `*no-init*` flag variable to `repl.lisp` — when set, prevents any init file from being loaded
- [x] 1.3 Add `resolve-init-file-path` helper function — returns the expanded init file path (checking `*no-init*`, `*init-file-path*`, defaulting to `~/.config/clotcad/init.lisp`, handling relative paths)
- [x] 1.4 Add `load-init-file-ui` function — reads a Lisp file, populates `*import-forms*`, and posts a wake event to trigger the `process-import-tick` pipeline
- [x] 1.5 Add `load-init-file-headless` function — reads a Lisp file and evaluates each form synchronously with error handling (catch errors, print to stderr, continue)
- [x] 1.6 Add `load-init-file` dispatcher — checks `*no-init*`, then checks if the init file exists, warns if `--init` path doesn't exist, returns nil gracefully when no init file

## 2. Wire init-file loading into startup paths

- [x] 2.1 Modify `start-viewer` in `lifecycle.lisp` — call `load-init-file-ui` *after* `initialize-viewer` and `start-render-loop` but *before* `%viewer-run`. Do NOT block — the import tick mechanism runs asynchronously through the drain queue
- [x] 2.2 Modify headless startup in `lifecycle.lisp` — call `load-init-file-headless` synchronously before `start-slynk` / `start-alive` returns (or before `wait-forever`)
- [x] 2.3 Modify `bootstrap` in `lifecycle.lisp` — add `load-init-file-headless` call before `start-viewer` (so init file runs before the viewer is constructed, giving a chance to set variables the viewer might use)

## 3. Update run.sh CLI argument parsing

- [x] 3.1 Add `--init FILE` and `--no-init` to usage text and argument parsing in `scripts/run.sh`
- [x] 3.2 For `--viewer` mode: prepend `--eval "(setf clotcad::*init-file-path* \"$INIT_FILE\")"` when `--init` is given, or `--eval "(setf clotcad::*no-init* t)"` when `--no-init` is given
- [x] 3.3 For `--slynk` and `--alive` modes: same as 3.2 — variables are set before mode-specific startup commands
- [x] 3.4 If both `--init` and `--no-init` are passed, `--no-init` wins (and a warning is emitted)

## 4. Update documentation

- [x] 4.1 Update `AGENTS.md` to document the `~/.config/clotcad/init.lisp` facility, the `--init` and `--no-init` CLI arguments, and their interaction
- [x] 4.2 Update `scripts/run.sh` usage text to include `--init FILE` and `--no-init`

## 5. Add tests

- [x] 5.1 Add test for `load-init-file-headless` — verify forms are evaluated in order and errors don't abort
- [x] 5.2 Add test for `resolve-init-file-path` — verify `--init` overrides default, `--no-init` skips loading, relative paths resolve correctly, non-existent file returns nil
- [x] 5.3 Add test for `bootstrap` init integration — mock `%viewer-create` and verify `load-init-file-headless` is called before `start-viewer`
