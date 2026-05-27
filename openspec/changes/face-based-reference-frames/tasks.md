## 1. Frame module implementation

- [x] 1.1 Create `src/viewer/frame.lisp` defining a `frame` class with slots `origin`, `x-axis`, `y-axis`, `z-axis` (each a list of 3 double-floats)
- [x] 1.2 Implement `make-frame-on-face` with `:u`, `:v`, `:point` keyword args
- [x] 1.3 Implement tangent plane logic for non-planar faces (use `face-normal-at-center` or compute at given UV/point)
- [x] 1.4 Implement accessors: `frame-origin`, `frame-x-axis`, `frame-y-axis`, `frame-z-axis`
- [x] 1.5 Implement `frame-to-location` that converts frame to an OCCT `gp_Trsf` via the assembly location API
- [x] 1.6 Implement `make-frame-on-plane` for frame construction without a face
- [x] 1.7 Write enriched markdown docstrings for every new public function and the `frame` class in `frame.lisp` using the format: brief description, `- **param** ...` for each parameter, `**Returns:**`, `**Example:**` with code block, and `**See also:**` linking related functions

## 2. ASDF and package updates

- [x] 2.1 Add frame.lisp to `clotcad.asd`
- [x] 2.2 Export all new public symbols from `:clotcad` package
- [x] 2.3 Ensure frame functions are available in `:clotcad-user`

## 3. Tests

- [x] 3.1 Create `t/frame.lisp` with tests for `make-frame-on-face` on planar faces (box faces)
- [x] 3.2 Test `make-frame-on-face` at specific UV and 3D point parameters
- [x] 3.3 Test `make-frame-on-face` on non-planar faces (cylinder, sphere, torus)
- [x] 3.4 Test frame accessors return correct values
- [x] 3.5 Test `frame-to-location` produces a valid OCCT location
- [x] 3.6 Test `make-frame-on-plane` with various orientations
- [x] 3.7 Add test system to `clotcad.asd`

## 4. API reference documentation

- [x] 4.1 Add frame function signatures and examples to `docs/clotcad-api.md` (make-frame-on-face, make-frame-on-plane, frame accessors, frame-to-location)
