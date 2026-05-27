## Context

cl-occt provides `face-center` and `face-normal-at-center` for individual face properties, and `make-location` for creating translation transformations. But there is no integrated "give me a usable coordinate system from this face" abstraction.

## Goals / Non-Goals

**Goals:**
- Derive a complete right-handed coordinate frame from any planar face.
- Support non-planar faces via tangent plane at a specified point.
- Convert frames to OCCT locations for shape placement.
- Provide a constructor for frames from raw parameters (no face needed).

**Non-Goals:**
- Frame animation or interpolation.
- Automatic frame alignment to sketch boundaries.
- Frame editing after construction (immutable).

## Decisions

### D1: Frame is a simple CLOS class
- Slots: `origin`, `x-axis`, `y-axis`, `z-axis` — each a list of 3 double-floats.
- Immutable after construction.
- **Rationale**: Simple, inspectable, serializable. Matches how AI agents and humans reason about coordinate systems.

### D2: For planar faces, frame is well-defined
- Origin = face center (or UV/3D point).
- Z-axis = face outward normal.
- X-axis = face U-direction.
- Y-axis = Z × X (cross product) for right-handedness.

### D3: For non-planar faces, tangent plane at point
- If no point is specified: use face center.
- Compute surface normal at that point → Z-axis.
- X/Y are the surface UV tangent directions projected onto the tangent plane.
- **Rationale**: Tangent plane is the natural "workplane" for placing features on curved surfaces.

### D4: frame-to-location constructs a gp_Trsf
- Uses the assembly location API (`make-location`, `compose-locations`) rather than raw gp_Trsf construction.
- **Rationale**: Composable with other OCCT location operations.

## Risks / Trade-offs

- **[Curved surfaces] Tangent plane validity** — On high-curvature surfaces, the tangent plane is only locally valid. Mitigation: document this limitation.
- **[Coordinate system handedness] Right-hand rule** — The cross product Z × X for Y gives a right-handed system. This matches OCCT convention.

## Open Questions

- Should frame accept a named face designator (e.g., `:my-box/top-face`) or only raw face shapes?
- Answer: Both. `make-frame-on-face` accepts any shape designator that resolves to a face.
