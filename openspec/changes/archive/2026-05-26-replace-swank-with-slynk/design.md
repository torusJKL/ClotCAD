## Context

The project currently uses Swank as its SLIME IDE backend. Slynk is its actively maintained fork/evolution that serves as the native backend for SLY. The migration replaces Swank with Slynk.

The project starts the backend in two contexts:
1. **Distribution (core dump)**: `bootstrap` in `lifecycle.lisp` uses `find-symbol` to locate `create-server` in `:swank`
2. **Development**: `start.lisp` quickloads `:swank` then starts the server

Both use the same pattern: dedicated SBCL thread, port 4005, `cl-occt-user` as default package.

## Goals / Non-Goals

**Goals:**
- Replace Swank with Slynk as the IDE backend
- SLY works with the new backend (SLIME is not supported — Slynk's protocol differs from Swank's)
- Preserve all current behavior: port 4005, dedicated thread, `cl-occt-user` package binding, graceful fallback
- Update all documentation and distribution artifacts

**Non-Goals:**
- SLIME backward compatibility (SLIME uses the Swank protocol which is incompatible with Slynk's internals)
- Adding nREPL support
- Changing the port, thread model, or package binding strategy
- Adding new Slynk-specific features beyond basic connectivity
- Changing the soft-dependency pattern (Slynk is still loaded via `find-symbol`, not hard ASDF dependency)

## Decisions

1. **Use `find-symbol` pattern (same as Swank)**
   - Slynk is NOT added as an ASDF dependency. The `find-symbol` / graceful-fallback pattern is preserved so the viewer works even if Slynk is not available.
   - Alternative considered: hard dependency via ASDF. Rejected because it would break the viewer when Slynk isn't installed.

2. **Quickload `:slynk` instead of `:swank`**
   - In `make-core.lisp` and `start.lisp`, change `(ql:quickload :swank)` to `(ql:quickload :slynk)`
   - Slynk is available on Quicklisp and is the recommended replacement for Swank.

3. **Update package lookup from `:swank` to `:slynk`**
   - `(find-symbol "CREATE-SERVER" :swank)` → `(find-symbol "CREATE-SERVER" :slynk)`
   - `(find-symbol "*DEFAULT-WORKER-THREAD-BINDINGS*" :swank)` → `(find-symbol "*DEFAULT-WORKER-THREAD-BINDINGS*" :slynk)`
   - Slynk's API is intentionally compatible with Swank's.

4. **Thread name change from "swank"/"cl-occt-slime" to "slynk"**
   - Update thread names to `"slynk"` for consistency with the new backend.

5. **SLY-only — no Swank package compatibility layer**
   - SLIME sends `swank:swank-require` and other `swank:`-prefixed symbols that Slynk cannot satisfy without a fragile compatibility shim. The Slynk project does not provide an official `swank` compatibility package for Quicklisp.
   - Decision: do NOT create or maintain a SWANK compatibility package. Users MUST connect via SLY (which speaks Slynk natively).
   - Alternatives considered and rejected:
     - `make-package :swank :use '(:slynk)` — insufficient because SLIME also sends contrib module symbols (`swank-repl`, `swank-indentation`, etc.) that don't exist in either package.
     - Creating a comprehensive `swank-require` mapping — introduces ongoing maintenance burden, and the protocol mismatch between SLIME 2.x and Slynk 1.x causes further issues.
   - Consequence: README, AGENTS.md, and all docs updated to reference SLY, not SLIME.

6. **Update distribution-packaging change artifacts**
   - The `linux-distribution-packaging` change references Swank in its design, spec, and tasks. These need updating to reflect Slynk.

7. **Update README.md**
   - If README.md references Swank, update to Slynk. Remove SLIME connection instructions; add SLY connection instructions.

## Risks / Trade-offs

- **Slynk API divergence**: If future Slynk versions change the API, the `find-symbol` pattern already handles this gracefully (falls back to no backend). Monitor Slynk releases.
- **Quicklisp availability**: Slynk must be available via Quicklisp for both core dump and development scenarios. Slynk is well-established on Quicklisp — low risk.
- **Existing SLY users**: This change is neutral-to-positive for SLY users since Slynk is the native backend for SLY.
