## Why

The project currently runs a Slynk server for SLY/SLIME IDE connectivity. Adding an Alive LSP server enables Visual Studio Code and other LSP-compatible editors to connect to the running Lisp image, providing IDE features (completion, diagnostics, jump-to-definition) without requiring SLY. This broadens editor support and improves the developer experience.

## What Changes

- Clone `alive-lsp` repository as a dependency in `lib/alive-lsp/`, pinned to a specific commit/tag for reproducibility
- Add `(ql:quickload :alive-lsp)` to `scripts/make-core.lisp` so it's available in the core dump
- Add Alive LSP server startup to `scripts/start.lisp` (alongside Slynk on port 4006)
- Add Alive LSP server startup to `src/viewer/lifecycle.lisp` `bootstrap` function (alongside Slynk for distribution)
- Add `alive-lsp-dir` variable and `alive-lsp` recipe to `justfile`
- **Patch alive-lsp source** to add `:default-package` parameter threaded through `start` → state → eval handler, so evaluations default to `cl-occt-user` instead of `cl-user`
- Update `AGENTS.md` to document Alive LSP port and threading model
- Preserve: Slynk on port 4005 remains unchanged; Alive LSP runs on port 4006 in a separate thread; graceful fallback if Alive LSP is unavailable

## Capabilities

### New Capabilities
- `alive-lsp-server`: The Alive LSP server, its startup lifecycle, thread model, port configuration, AND the `cl-occt-user` package as the default evaluation namespace

### Modified Capabilities
- `lisp-ide-backend`: The existing Slynk-based Lisp IDE backend spec needs to acknowledge Alive LSP as a supplementary server

## Impact

- **`scripts/make-core.lisp`**: Add `(ql:quickload :alive-lsp)`
- **`scripts/start.lisp`**: Add Alive LSP startup block alongside Slynk
- **`src/viewer/lifecycle.lisp`**: Add Alive LSP startup to `bootstrap` alongside Slynk
- **`justfile`**: Add `alive-lsp-dir` variable, `alive-lsp` recipe, make `core` depend on `alive-lsp`
- **`AGENTS.md`**: Document Alive LSP port (4006), threading model, and dependency setup
- **`lib/alive-lsp/`**: New git clone dependency
