## Why

Creating a 2D profile for a CAD operation (extrude, cut, sweep, revolve) currently requires manually constructing edges, a wire, and placing it as a face on a plane using 6 raw float coordinates. This is verbose and error-prone. A `sketch-on-face` system lets users create profiles by composing high-level primitives (rect, circle, slot, polygon, line-chain) on a face's natural coordinate frame, with automatic wire and face assembly.

## What Changes

- **sketch-on-face**: Entry point that evaluates sketch primitives on a face's coordinate frame and returns a face (default), a list of faces, or a wire.
- **Sketch primitives**: `rect`, `circle`, `slot`, `polygon`, `line-chain` — each creates the corresponding 2D wire on the sketch plane.
- **Result types**: Default returns a single face (compound face with holes for multiple profiles). `:result-type :faces` returns separate faces. `:result-type :wire` returns a wire.
- **Positional references**: Sketch primitives accept vertex designators (compound symbols) in place of explicit 2D points.
- **extrude-from-face**: Convenience combining `sketch-on-face` + prism + boolean cut.
- **Tests** for all sketch operations.
- **API reference** documentation updated.

## Capabilities

### New Capabilities
- `sketch-helpers`: Create profiles on faces with primitives, multiple profile handling, and positional references to existing geometry.

### Modified Capabilities
- (none)

## Impact

- New file `src/viewer/sketch.lisp`
- New test file `t/sketch.lisp`
- Updates to `docs/clotcad-api.md`
- cl-occt dependency unchanged (uses `make-edge`, `make-wire`, `make-face-on-plane`, `make-prism`)
