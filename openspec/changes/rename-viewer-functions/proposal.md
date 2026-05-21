## Why

Calling `(cl-occt:make-sphere 20)` instead of `(make-sphere 20)` creates friction in the REPL — the qualified prefix is noisy and slows down interactive use. We need a workspace package (`cl-occt-user`) that `:use`s both `cl-occt` and `cl-occt-viewer` so users can type bare symbol names. But two symbols (`fit-all`, `set-antialiasing`) are exported by both packages, causing a conflict. Renaming the viewer's versions to unique names eliminates the conflict and makes the API clearer.

## What Changes

- **Rename** `cl-occt-viewer:fit-all` → `fit-view` (fits all shapes to viewport)
- **Rename** `cl-occt-viewer:set-antialiasing` → `set-view-aa` (enables/disables antialiasing)
- **Create** `:cl-occt-user` workspace package that `:use`s `:cl`, `:cl-occt`, `:cl-occt-viewer`
- **Update** `start.lisp` to land in `:cl-occt-user` instead of `:cl-occt-viewer`
- **Update** README "Usage" section to demonstrate the unqualified workflow
- **Add** unit tests for renamed functions

## Capabilities

### New Capabilities
- `user-workspace`: Convenience package for REPL users, providing unqualified access to both modeling and viewer functions.

### Modified Capabilities
<!-- No existing specs to modify -->

## Impact

- **Source**: `src/viewer/ui.lisp` (2 defuns), `src/viewer/package.lisp` (4 export symbols)
- **Tests**: `t/viewer-tests.lisp` (update test calls + add new tests)
- **Docs**: `README.md` (Usage section, add cl-occt-user to architecture diagram)
- **Startup**: `start.lisp` (change `in-package`)
- **No breaking change for saved scripts**: old names were never stable API; viewers-specific convenience functions
