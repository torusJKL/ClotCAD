## 1. Core Implementation — Slynk Replacement

- [x] 1.1 Update `bootstrap` in `src/viewer/lifecycle.lisp`: change `:swank` package lookup to `:slynk`, update thread name to `"slynk"`, update `*default-worker-thread-bindings*` and `create-server` symbol references
- [x] 1.2 Update `scripts/start.lisp`: replace `(ql:quickload :swank)` with `(ql:quickload :slynk)`, update `:swank` symbol lookups to `:slynk`, update thread name to `"slynk"`
- [x] 1.3 Update `scripts/make-core.lisp`: replace `(ql:quickload :swank)` with `(ql:quickload :slynk)`

## 2. Test Updates

- [x] 2.1 Update `t/viewer-tests.lisp` — replace `:swank` references with `:slynk` in the Slynk-unavailable test scenario

## 3. Documentation Updates

- [x] 3.1 Update `AGENTS.md`: replace all "Swank" references with "Slynk" (build command, threading, port)
- [x] 3.2 Update `README.md`: replace any "Swank" references with "Slynk"
- [x] 3.3 Update `justfile`: replace "Swank" references in recipe descriptions with "Slynk"

## 4. Distribution-Packaging Artifacts

- [x] 4.1 Update `openspec/changes/linux-distribution-packaging/design.md`: replace "Swank" with "Slynk" throughout
- [x] 4.2 Update `openspec/changes/linux-distribution-packaging/specs/distribution-packaging/spec.md`: replace "Swank" with "Slynk"
- [x] 4.3 Update `openspec/changes/linux-distribution-packaging/tasks.md`: replace "Swank" with "Slynk"

## 5. SLIME Compatibility (dropped — SLY only)

- [-] 5.1 SLIME compatibility shim — **DROPPED**: Slynk's protocol differs from Swank's; `swank:swank-require` and contrib module symbols cannot be satisfied without a fragile, high-maintenance compat layer. SLIME protocol mismatch (2.x vs Slynk 1.x) also causes issues. Users MUST use SLY.

## 6. Verify

- [x] 6.1 Run `just test` to verify tests pass with Slynk — **118 pass, 0 fail** ✓
- [x] 6.2 Verify SLY can connect to port 4005 and evaluate forms in `cl-occt-user` — **confirmed** ✓
- [x] 6.3 Verify graceful fallback works when Slynk is not available — **confirmed by test** ✓
- [x] 6.4 Clean up `swank-compat.lisp` and all compat calls from lifecycle, start.lisp, make-core.lisp, ASDF — **done** ✓
- [x] 6.5 Update design.md, spec.md, tasks.md to reflect SLY-only decision — **done** ✓
