## 1. Sketch module implementation

- [x] 1.1 Create `src/viewer/sketch.lisp` with `sketch-on-face` entry point: resolves face, creates frame, evaluates primitives in frame-local 2D coordinates, assembles result based on `:result-type`
- [x] 1.2 Implement `pnt` (2D point constructor)
- [x] 1.3 Implement `rect` sketch primitive
- [x] 1.4 Implement `circle` sketch primitive
- [x] 1.5 Implement `slot` sketch primitive
- [x] 1.6 Implement `polygon` sketch primitive
- [x] 1.7 Implement `line-chain` sketch primitive
- [x] 1.8 Implement positional reference resolution: accept vertex designators in sketch primitives, project to 2D coordinates on the sketch plane
- [x] 1.9 Implement `:result-type :faces` (list of separate faces) and `:result-type :wire` code paths
- [x] 1.10 Implement compound face assembly for default mode (outer wire + inner wires for holes)
- [x] 1.11 Implement `extrude-from-face` convenience: sketch-on-face + prism + boolean cut into a designator
- [x] 1.12 Write enriched markdown docstrings for every new public function in `sketch.lisp` using the format: brief description, `- **param ...` for each parameter, `**Returns:**`, `**Example:**` with code block, and `**See also:**` linking related functions

## 2. ASDF and package updates

- [x] 2.1 Add sketch.lisp to `clotcad.asd`
- [x] 2.2 Export all new public symbols from `:clotcad` package
- [x] 2.3 Ensure sketch functions are available in `:clotcad-user`

## 3. Tests

- [x] 3.1 Create `t/sketch.lisp` with tests for all sketch primitives (rect, circle, slot, polygon, line-chain)
- [x] 3.2 Test `:result-type :faces` and `:result-type :wire` modes
- [x] 3.3 Test compound face assembly with multiple primitives
- [x] 3.4 Test positional references (vertex designators in primitives)
- [x] 3.5 Test `extrude-from-face` produces a valid boolean result
- [x] 3.6 Add test system to `clotcad.asd`

## 4. API reference documentation

- [x] 4.1 Add sketch function signatures and examples to `docs/clotcad-api.md` (sketch-on-face, all primitives, pnt, result types, extrude-from-face)
- [x] 4.2 Add a "Sketching on Faces" usage guide with a worked example
