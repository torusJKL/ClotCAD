## 1. Core Implementation

- [x] 1.1 Create `src/viewer/text.lisp` with font fallback chain, plane-keyword-to-frame mapping, and `make-3d-text` function
- [x] 1.2 Wire `make-3d-text` into `src/package.lisp` (add `:make-3d-text` to `clotcad` package export)
- [x] 1.3 Add `text.lisp` to ASDF system definition in `clotcad.asd`

## 2. Documentation

- [x] 2.1 Add `make-3d-text(s, ..options)` entry to cheatsheet under a new "3D Text" section
- [x] 2.2 Add `make-3d-text` to Roter api-reference documentation with signature, plane table, and examples

## 3. Testing

- [x] 3.1 Add unit tests for font fallback logic (mock `make-brep-font-from-name` to return nil for first N attempts)
- [x] 3.2 Add unit tests for plane keyword → frame mapping (:xy, :xz, :yz, face, frame)
- [x] 3.3 Add integration test: produce shape and verify it's non-nil and has correct topology type
