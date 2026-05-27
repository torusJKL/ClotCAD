## Context

Creating a profile for extrusion currently looks like:
```lisp
(make-face-on-plane
  (make-wire (make-circle2d 0 0 10))
  0 0 0 0 0 1)
```
The 6-float plane definition is opaque. The wire/face construction is boilerplate. cl-occt provides all the building blocks but no composition layer.

## Goals / Non-Goals

**Goals:**
- Let users sketch on a face's natural coordinate frame (no explicit plane specification).
- Provide common primitives (rect, circle, slot, polygon, line-chain).
- Support three output modes: single face (compound), separate faces, or wire.
- Support positional references to existing geometry vertices.
- Extrude convenience: sketch + prism + cut in one step.

**Non-Goals:**
- Parametric constraint solver (tangency, dimension constraints).
- 3D sketches or 3D paths.
- Freehand/dynamic sketching.
- Interactive sketcher UI — programmatic only.

## Decisions

### D1: Sketch returns a face by default
`(sketch-on-face :top ...)` returns a single face (or compound face with holes for multiple profiles).
- **Rationale**: Face is the most common input for extrusion/cut operations. Compound face naturally models pocket+island.

### D2: :result-type :faces returns a list
- **Rationale**: When the user wants separate features (e.g., two separate bosses), they need individual faces for independent extrusion.

### D3: :result-type :wire returns a wire
- **Rationale**: Wires are needed for sweep and some loft operations.

### D4: Positional references via vertex designators
Sketch primitives accept vertex designators (compound symbols or any `resolve-shape`-compatible vertex reference) wherever a 2D point is expected. The vertex is projected to the sketch plane's 2D coordinates.
- **Rationale**: Ties sketches to existing geometry for parametric behavior.

### D5: Multiple primitives compound by default
When multiple sketch primitives are given, the outer-most wire becomes the face boundary and inner wires become holes. This matches the intuition of "a face with cutouts."
- **Rationale**: Most common pattern in CAD (pocket with central hole). The `:faces` mode is for the explicit "separate features" case.

## Risks / Trade-offs

- **[Geometry] Sketch primitives must be closed for face construction** — Open wires (e.g., line-chain :closed nil) cannot form a face. Mitigation: `:result-type :wire` for open profiles; face creation errors if wire is open.
- **[Projection] Vertex projection to 2D** — A vertex not on the sketch plane projects to the nearest point. Workable for nearby vertices; misleading for distant ones. Mitigation: document as "nearest point projection."
- **[Orientation] Sketch frame orientation** — X/Y axes of the frame determine sketch direction. The face UV coordinates define this. For most planar faces this is intuitive, but for rotated faces the sketch may appear sideways. Mitigation: let users override frame via `make-frame-on-plane`.

## Open Questions

- Should sketch primitives accept width/height as single numbers or as lists/vectors?
- Answer: Separate keyword arguments for clarity (rect takes width and height as separate args).
