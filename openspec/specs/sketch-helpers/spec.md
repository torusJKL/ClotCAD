# sketch-helpers Specification

## Purpose
TBD - created by archiving change sketch-helpers. Update Purpose after archive.
## Requirements
### Requirement: sketch-on-face creates a profile on a face
The system SHALL provide `(sketch-on-face face-designator &body sketch-primitives &key result-type)` that evaluates sketch primitives on a face's coordinate frame and returns the resulting geometry.

#### Scenario: Sketch returns a face by default
- **WHEN** user calls `(sketch-on-face :my-box/top-face (rect (pnt 2 2) 6 6))`
- **THEN** the system returns a planar face on the face's plane, bounded by a 6×6 rectangle inset 2mm from the face origin

#### Scenario: Sketch with :result-type :faces returns a list
- **WHEN** user calls `(sketch-on-face :my-box/top-face (rect (pnt 2 2) 6 6) (circle (pnt 5 5) 1) :result-type :faces)`
- **THEN** the system returns a list of two separate face objects

#### Scenario: Sketch with :result-type :wire returns a wire
- **WHEN** user calls `(sketch-on-face :my-box/top-face (rect (pnt 2 2) 6 6) :result-type :wire)`
- **THEN** the system returns a single wire object (the rectangle boundary)

#### Scenario: Multiple primitives with default result-type creates compound face
- **WHEN** user calls `(sketch-on-face :my-box/top-face (rect (pnt 2 2) 8 8) (circle (pnt 6 6) 2))`
- **THEN** the system returns a single face with an outer wire (the rect) and one inner wire (the circle), creating a face with a hole
- **AND** the face is valid and can be used in boolean/extrude operations

### Requirement: rect sketch primitive
The system SHALL provide `(rect corner width height)` that creates a rectangle. `corner` is a 2D point from `(pnt x y)`, or a vertex designator for positional reference.

#### Scenario: Rectangle with explicit corner
- **WHEN** user calls `(rect (pnt 0 0) 10 20)`
- **THEN** the system returns a closed wire forming a 10×20 rectangle with the given corner at (0,0)

#### Scenario: Rectangle with vertex reference
- **WHEN** user calls `(rect :my-box/edge-start 10 20)`
- **THEN** the system resolves the vertex, uses its 2D projection as the corner

### Requirement: circle sketch primitive
The system SHALL provide `(circle center radius)` that creates a circle. `center` is a 2D point or vertex designator.

#### Scenario: Circle with explicit center
- **WHEN** user calls `(circle (pnt 0 0) 5)`
- **THEN** the system returns a closed wire forming a circle of radius 5 centered at (0,0)

#### Scenario: Circle with vertex reference
- **WHEN** user calls `(circle :my-box/top-face-center 3)`
- **THEN** the system resolves the vertex position and creates a circle centered there

### Requirement: slot sketch primitive
The system SHALL provide `(slot center width height radius)` that creates a slot (rectangle with rounded ends). `center` is a 2D point or vertex designator.

#### Scenario: Slot with explicit center
- **WHEN** user calls `(slot (pnt 0 0) 12 6 2)`
- **THEN** the system returns a closed wire forming a slot: 12mm long, 6mm wide, with 2mm corner radius

### Requirement: polygon sketch primitive
The system SHALL provide `(polygon &rest points)` that creates a closed polygon from a list of 2D points or vertex designators.

#### Scenario: Triangle from explicit points
- **WHEN** user calls `(polygon (pnt 0 0) (pnt 5 0) (pnt 2.5 5))`
- **THEN** the system returns a closed wire forming a triangle

#### Scenario: Mixed point and vertex references
- **WHEN** user calls `(polygon (pnt 0 0) :my-box/edge-start :my-box/other-vertex)`
- **THEN** the system resolves vertex references and creates the polygon

### Requirement: line-chain sketch primitive
The system SHALL provide `(line-chain &rest points &key closed)` that creates an open or closed chain of line edges.

#### Scenario: Open line chain
- **WHEN** user calls `(line-chain (pnt 0 0) (pnt 5 0) (pnt 5 5) :closed nil)`
- **THEN** the system returns a wire formed by two connected edges, not closed back to the start

#### Scenario: Closed line chain
- **WHEN** user calls `(line-chain (pnt 0 0) (pnt 5 0) (pnt 5 5) :closed t)`
- **THEN** the system returns a closed wire (triangle)

### Requirement: pnt creates a 2D point designator
The system SHALL provide `(pnt x y)` as syntactic sugar for creating a 2D point within a sketch context. Points are relative to the sketch's coordinate frame.

#### Scenario: pnt within sketch
- **WHEN** user calls `(pnt 3.5 7.0)`
- **THEN** the system returns a point designator that resolves to (3.5, 7.0) in the sketch's local 2D coordinates

### Requirement: Positional references resolve vertex designators
The system SHALL allow vertex designators (compound symbols, model names resolved to vertices) as arguments to sketch primitives where a 2D point is expected.

#### Scenario: Vertex reference in rect
- **WHEN** user calls `(sketch-on-face :box/top-face (rect :box/edge-start 10 10))`
- **THEN** the system resolves `:box/edge-start` to a vertex, projects it to the sketch plane's 2D coordinates, and uses it as the rectangle corner

### Requirement: extrude-from-face convenience
The system SHALL provide `(extrude-from-face face-designator sketch &key depth direction)` as shorthand for combining a sketch-on-face with a prism into a boolean cut on the parent.

#### Scenario: Extrude from face
- **WHEN** user calls `(extrude-from-face :box/top-face (sketch-on-face :box/top-face (circle (pnt 5 5) 2)))`
- **THEN** the system creates a circular face on :box/top-face, extrudes it along the face normal (into the body), and performs a boolean cut, returning the modified shape

