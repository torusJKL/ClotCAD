## 1. Dependency Setup

- [x] 1.1 Add `alive-lsp-dir` variable and `alive-lsp` recipe to `justfile`
- [x] 1.2 Make `just core` depend on `just alive-lsp`
- [x] 1.3 Pin alive-lsp clone to a specific commit/tag in `justfile` for reproducibility
- [x] 1.4 Patch alive-lsp source: add `default-package` slot to state struct (`src/session/state.lisp`)
- [x] 1.5 Patch alive-lsp source: add `:default-package` param to `start`, thread through `accept-conn` → `state:create` (`src/server.lisp`)
- [x] 1.6 Patch alive-lsp source: use `(state:default-package state)` instead of `"cl-user"` in eval handler (`src/session/handler/eval.lisp`)

## 2. Core Implementation — scripts and lifecycle

- [x] 2.1 Add Alive LSP central registry push and quickload to `scripts/make-core.lisp`
- [x] 2.2 Add Alive LSP central registry push, quickload, and thread-based startup to `scripts/start.lisp` (alongside Slynk, port 4006)
- [x] 2.3 Add Alive LSP startup to `bootstrap` in `src/viewer/lifecycle.lisp` (alongside Slynk, port 4006)

## 3. Documentation Updates

- [x] 3.1 Update `AGENTS.md`: add Alive LSP port (4006), threading model, and build instructions
- [x] 3.2 Update `README.md`: add Alive LSP port (4006), connection instructions, and build prerequisites

## 4. Verify

- [x] 4.1 Run `just alive-lsp` to verify git clone works
- [x] 4.2 Run `just core` to verify Alive LSP is included in the core dump
- [x] 4.3 Run `just start` and verify both Slynk (4005) and Alive LSP (4006) start
- [x] 4.4 Verify graceful fallback when alive-lsp is not available (temporarily remove `lib/alive-lsp/`)
- [x] 4.5 Connect LSP client and verify evaluations default to `cl-occt-user` package
