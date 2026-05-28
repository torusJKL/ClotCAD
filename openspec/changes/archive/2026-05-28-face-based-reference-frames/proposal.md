## Why

Placing a sketch or feature on a face currently requires constructing a coordinate frame manually: find the face center, compute the normal, build a gp_Ax2. The 6-float interface of `make-face-on-plane` (point + normal as raw doubles) is opaque to both humans and AI agents. A `make-frame-on-face` function that derives a coordinate frame directly from a face makes it possible to answer "where is this face?" and "how do I put something on it?" in a single call.

## What Changes

- **frame class**: A new class with origin, X-axis, Y-axis, Z-axis slots (each a list of 3 double-floats).
- **make-frame-on-face**: Construct a coordinate frame from a face's geometry. Origin at face center (or specified UV/3D point), Z = face normal, X/Y = face UV directions. For non-planar faces, produces a tangent plane at the given point.
- **frame accessors**: `frame-origin`, `frame-x-axis`, `frame-y-axis`, `frame-z-axis`.
- **frame-to-location**: Convert a frame to an OCCT `gp_Trsf` for use with `move-shape`.
- **make-frame-on-plane**: Construct a frame from a point+normal definition (without a face).
- **Tests** for all frame operations.
- **API reference** documentation updated.

## Capabilities

### New Capabilities
- `face-based-reference-frames`: Construct coordinate frames from faces — origin, X/Y/Z axes aligned to face normal and UV parameters. Tangent plane on non-planar faces.

### Modified Capabilities
- (none)

## Impact

- New file `src/viewer/frame.lisp`
- New test file `t/frame.lisp`
- Updates to `docs/clotcad-api.md`
- cl-occt dependency unchanged (uses `face-center`, `face-normal-at-center`, `face-surface-type` from cl-occt)
