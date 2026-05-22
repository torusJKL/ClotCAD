## Context

The project currently runs a single Lisp IDE server — Slynk on port 4005 — for SLY/SLIME connectivity. Adding an Alive LSP server on port 4006 enables LSP-compatible editors (VS Code, Emacs with lsp-mode, etc.) to provide completion, diagnostics, and other IDE features. The Alive LSP server is a separate product from alive-lsp on GitHub, loaded via Quicklisp, and runs as a companion to Slynk — not a replacement.

The user has already prototyped this with a local git clone of alive-lsp in `lib/alive-lsp/` and confirmed it loads and starts without issues.

## Goals / Non-Goals

**Goals:**
- Add an Alive LSP server alongside the existing Slynk server
- Alive LSP runs on port 4006 in a dedicated thread
- Alive LSP uses the same `cl-occt-user` package for evaluations
- Local git clone of alive-lsp at `lib/alive-lsp/` for reproducibility and offline use
- Alive LSP is quickloaded into the core dump for distribution
- Graceful fallback if Alive LSP is unavailable (same pattern as Slynk)
- Update documentation (AGENTS.md) and build system (justfile)
- Follow the same patterns established by Slynk for consistency

**Non-Goals:**
- Replacing Slynk with Alive LSP (both servers coexist — different editors need different protocols)
- Adding Alive LSP as a hard ASDF dependency (same soft-dependency pattern as Slynk)
- Changing the Slynk port, thread model, or startup behavior
- Adding Alive LSP-specific features beyond basic startup and connectivity
- Packaging alive-lsp as a system dependency — it remains a Quicklisp library available via git clone

## Decisions

1. **Local git clone in `lib/alive-lsp/` (same pattern as `lib/cl-occt/`)**
   - Provides a reproducible dependency checked out at a known commit.
   - Added to `asdf:*central-registry*` in `make-core.lisp` and `start.lisp`.
   - Alternative considered: Quicklisp-only. Rejected because the alive-lsp project may not be on Quicklisp or may lag behind; a local checkout gives us control.

2. **Port 4006 alongside Slynk's port 4005**
   - Slynk and Alive LSP are independent servers with different wire protocols (Slynk for SLY, LSP for VS Code and LSP-compatible editors).
   - They can coexist without conflict because they listen on different ports and use different protocols.
   - Port 4006 is the next logical port after 4005.

3. **Same thread model as Slynk**
   - Alive LSP runs in its own SBCL thread named `"alive-lsp"`.
   - Uses `(loop (sleep 1))` to keep the thread alive.
   - Does not block the main/Qt thread.

4. **Soft dependency with graceful fallback (same pattern as Slynk)**
   - Alive LSP is NOT a hard ASDF dependency of `:cl-occt-viewer`.
   - Use `find-symbol` pattern or `handler-case` to gracefully handle the case where alive-lsp is not available.
   - This ensures the viewer still works even if alive-lsp is not cloned or quickloaded.

5. **Quickload into core dump (`make-core.lisp`)**
   - Add `(ql:quickload :alive-lsp :silent t)` to `make-core.lisp` so the distribution core dump includes it.
   - This avoids network access at distribution startup time.

6. **Justfile recipe `alive-lsp` added to clone and pin the dependency**
   - New `alive-lsp-dir` variable pointing to `lib/alive-lsp/`.
   - Clone is pinned to a specific commit/tag so the patch to alive-lsp source is reproducible.
   - `just core` depends on `just alive-lsp` (and transitively on submodules).
   - `just start` does NOT depend on `alive-lsp` because `start.lisp` handles both local and Quicklisp loading gracefully.

7. **Patch alive-lsp source for `:default-package` support**
   - Alive LSP's eval handler hardcodes `"cl-user"` as the default package (`src/session/handler/eval.lisp:20`). Since the viewer operates in `cl-occt-user`, we need to change that default.
   - Minimal patch: add `default-package` slot to the `state` struct, thread it from `alive/server:start` → `accept-conn` → `state:create`, then use `(state:default-package state)` instead of `"cl-user"` in the eval handler.
   - Alternative considered: monkey-patch at runtime via `advise`. Rejected because it's fragile and couples our startup code to alive-lsp internals.
   - Alternative considered: wait for upstream to add the feature. Rejected because we need it now and there's no timeline for upstream support.
   - The patch is small (3 files, ~10 lines total) and lives in our local clone, so it's self-contained and won't break on upstream updates (since we pin the commit).

## Risks / Trade-offs

- **alive-lsp project maturity**: The alive-lsp project may change API, have bugs, or become unmaintained. Mitigation: soft-dependency with graceful fallback means the viewer is unaffected if alive-lsp breaks.
- **Port conflict**: Port 4006 could conflict with another service on the user's machine. Mitigation: the thread model handles failures gracefully with a warning message.
- **Quicklisp availability for alive-lsp**: alive-lsp may not be on Quicklisp. Mitigation: local git clone at `lib/alive-lsp/` provides an alternative load path via ASDF central registry.
- **Two servers overhead**: Running both Slynk and Alive LSP consumes two TCP ports and two threads. This is negligible for a development tool.
- **Local patch divergence**: If we update the pinned alive-lsp commit, the patch may need rebasing if the eval handler or state struct changed upstream. Mitigation: the patch is small and focused (3 files); we can easily detect breakage by checking that the `:default-package` keyword still threads through.
