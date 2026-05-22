## Why

SLIME and SLY are the two dominant Common Lisp IDEs. Slynk is the backend that supports both — it is the actively maintained successor to Swank. Replacing Swank with Slynk ensures compatibility with both editors, unlocks newer features, and aligns with the broader Common Lisp ecosystem's direction.

## What Changes

- Replace Swank with Slynk as the Lisp IDE backend in the core dump distribution
- Update `bootstrap` in `lifecycle.lisp` to start Slynk instead of Swank
- Update `start.lisp` to load and start Slynk instead of Swank
- Update `make-core.lisp` to quickload Slynk instead of Swank
- Update all documentation references (AGENTS.md, README.md, justfile)
- Update `linux-distribution-packaging` change artifacts to reference Slynk
- Update test for graceful handling when Slynk is unavailable
- Preserve: port 4005, dedicated thread pattern, `cl-occt-user` package binding, graceful fallback if backend unavailable

## Capabilities

### New Capabilities
- `lisp-ide-backend`: The Lisp IDE backend server (Slynk), its startup lifecycle, thread model, and the `cl-occt-user` package as the default evaluation namespace

### Modified Capabilities
<!-- No existing specs to modify -->

## Impact

- **`src/viewer/lifecycle.lisp`**: Replace `swank:create-server` with `slynk:create-server`, `swank:*default-worker-thread-bindings*` with `slynk:*default-worker-thread-bindings*`, and `:swank` package lookup with `:slynk`
- **`scripts/start.lisp`**: Change `ql:quickload :swank` to `ql:quickload :slynk`, update symbol references
- **`scripts/make-core.lisp`**: Change `ql:quickload :swank` to `ql:quickload :slynk`
- **`t/viewer-tests.lisp`**: Update Swank → Slynk in test expectations
- **`AGENTS.md`**: Replace "Swank" with "Slynk"
- **`README.md`**: Replace "Swank" with "Slynk" (if referenced)
- **`justfile`**: Update "Swank" references in recipes
- **`openspec/changes/linux-distribution-packaging/`**: Update design, spec, and tasks to reference Slynk
