## ADDED Requirements

### Requirement: query-shape accepts predicate list with :where keyword
The system SHALL provide `(query-shape designator &key where coordinate-system)` that resolves a shape designator and applies a list of predicates. Each predicate is a function-like form `(predicate-name arg1 arg2 ...)`.

#### Scenario: Basic query-shape call
- **WHEN** user calls `(query-shape :my-box :where (list (face-p) (normal-along 0 0 1)))`
- **THEN** the system returns a list of face subshapes whose normal is aligned with +Z within the default angle tolerance

#### Scenario: Query with :coordinate-system :global
- **WHEN** user calls `(query-shape :my-box :where (list (face-p) (normal-along 0 0 1)) :coordinate-system :global)`
- **THEN** the system evaluates normals in the global/world coordinate frame

#### Scenario: Query with :coordinate-system :local
- **WHEN** user calls `(query-shape :my-box :where (list (face-p) (normal-along 0 0 1)) :coordinate-system :local)`
- **THEN** the system evaluates normals relative to the shape's own frame, ignoring any TopoDS_Location

### Requirement: face-p predicate
The system SHALL provide a `face-p` predicate that filters subshapes of type face.

#### Scenario: Only faces returned
- **WHEN** user calls `(query-shape :my-box :where (list (face-p)))`
- **THEN** the system returns only face subshapes (not edges, vertices, wires, or other types)

### Requirement: edge-p predicate
The system SHALL provide an `edge-p` predicate that filters subshapes of type edge.

#### Scenario: Edges only
- **WHEN** user calls `(query-shape :my-box :where (list (edge-p)))`
- **THEN** the system returns only edge subshapes

### Requirement: vertex-p predicate
The system SHALL provide a `vertex-p` predicate that filters subshapes of type vertex.

#### Scenario: Vertices only
- **WHEN** user calls `(query-shape :my-box :where (list (vertex-p)))`
- **THEN** the system returns only vertex subshapes

### Requirement: normal-along predicate
The system SHALL provide a `normal-along` predicate that filters planar faces whose outward normal is aligned with a given direction, within an optional angle tolerance.

#### Scenario: Face with normal in +Z
- **WHEN** user calls `(query-shape :my-box :where (list (face-p) (normal-along 0 0 1)))`
- **THEN** the system returns faces whose outward normal is within 1 degree of +Z

#### Scenario: Face with normal in -Z
- **WHEN** user calls `(query-shape :my-box :where (list (face-p) (normal-along 0 0 -1)))`
- **THEN** the system returns faces whose outward normal is within 1 degree of -Z

#### Scenario: Custom angle tolerance
- **WHEN** user calls `(query-shape :my-box :where (list (face-p) (normal-along 0 0 1 :angle-deg 5)))`
- **THEN** the system uses 5 degrees as the tolerance instead of the default 1 degree

### Requirement: surface-type predicate
The system SHALL provide a `surface-type` predicate that filters faces by their underlying surface type (e.g. `:plane`, `:cylinder`, `:sphere`, `:cone`, `:torus`).

#### Scenario: Planar faces only
- **WHEN** user calls `(query-shape :my-box :where (list (face-p) (surface-type :plane)))`
- **THEN** the system returns only planar faces

#### Scenario: Cylindrical faces only
- **WHEN** user calls `(query-shape (make-cylinder 5 20) :where (list (face-p) (surface-type :cylinder)))`
- **THEN** the system returns only the cylindrical face (not the top/bottom planar faces)

### Requirement: curve-type predicate
The system SHALL provide a `curve-type` predicate that filters edges by their underlying curve type (e.g. `:line`, `:circle`, `:ellipse`).

#### Scenario: Linear edges only
- **WHEN** user calls `(query-shape :my-box :where (list (edge-p) (curve-type :line)))`
- **THEN** the system returns only straight edges

#### Scenario: Circular edges only
- **WHEN** user calls `(query-shape :my-cylinder :where (list (edge-p) (curve-type :circle)))`
- **THEN** the system returns only circular edges

### Requirement: longer-than predicate
The system SHALL provide a `longer-than` predicate that filters edges longer than a given length.

#### Scenario: Edges longer than threshold
- **WHEN** user calls `(query-shape :my-box :where (list (edge-p) (longer-than 15)))`
- **THEN** the system returns edges whose 3D length exceeds 15mm

### Requirement: shorter-than predicate
The system SHALL provide a `shorter-than` predicate that filters edges shorter than a given length.

#### Scenario: Edges shorter than threshold
- **WHEN** user calls `(query-shape :my-box :where (list (edge-p) (shorter-than 5)))`
- **THEN** the system returns edges whose 3D length is less than 5mm

### Requirement: larger-than predicate
The system SHALL provide a `larger-than` predicate that filters faces with area larger than a given value.

#### Scenario: Large faces only
- **WHEN** user calls `(query-shape :my-box :where (list (face-p) (larger-than 200)))`
- **THEN** the system returns faces whose area exceeds 200mm²

### Requirement: smaller-than predicate
The system SHALL provide a `smaller-than` predicate that filters faces with area smaller than a given value.

#### Scenario: Small faces only
- **WHEN** user calls `(query-shape :my-box :where (list (face-p) (smaller-than 100)))`
- **THEN** the system returns faces whose area is less than 100mm²

### Requirement: max-by predicate
The system SHALL provide a `max-by` predicate that selects the single subshape with the maximum value of a given measurement function.

#### Scenario: Largest face by area
- **WHEN** user calls `(query-shape :my-box :where (list (face-p) (max-by #'face-area)))`
- **THEN** the system returns the single face with the largest area

#### Scenario: Longest edge
- **WHEN** user calls `(query-shape :my-box :where (list (edge-p) (max-by #'edge-length)))`
- **THEN** the system returns the single longest edge

### Requirement: min-by predicate
The system SHALL provide a `min-by` predicate that selects the single subshape with the minimum value of a given measurement function.

#### Scenario: Smallest face by area
- **WHEN** user calls `(query-shape :my-box :where (list (face-p) (min-by #'face-area)))`
- **THEN** the system returns the single face with the smallest area

### Requirement: z-center predicate
The system SHALL provide `z-center`, `y-center`, `x-center` predicates that filter subshapes whose center Z (Y, X) coordinate is within a tolerance of a given value.

Center computation uses `face-center` for faces and bounding-box midpoint for edges and vertices.

#### Scenario: Face at specific Z height
- **WHEN** user calls `(query-shape :my-box :where (list (face-p) (z-center 10)))`
- **THEN** the system returns faces whose center Z coordinate is within floating-point tolerance of 10

#### Scenario: Face at specific Z with tolerance
- **WHEN** user calls `(query-shape :my-box :where (list (face-p) (z-center 10 :tolerance 0.1)))`
- **THEN** the system returns faces whose center Z is within 0.1mm of 10

#### Scenario: Edge at specific X coordinate
- **WHEN** user calls `(query-shape :my-box :where (list (edge-p) (x-center 5)))`
- **THEN** the system returns edges whose bounding-box center X is within tolerance of 5

#### Scenario: Vertex at specific Y coordinate
- **WHEN** user calls `(query-shape :my-box :where (list (vertex-p) (y-center 0 :tolerance 0.01)))`
- **THEN** the system returns vertices whose bounding-box center Y is within 0.01mm of 0

### Requirement: edge-along predicate
The system SHALL provide an `edge-along` predicate that filters edges whose direction is aligned with a given direction vector.

#### Scenario: Edges parallel to X axis
- **WHEN** user calls `(query-shape :my-box :where (list (edge-p) (edge-along 1 0 0)))`
- **THEN** the system returns edges whose direction is along the X axis

#### Scenario: Edges aligned within angle tolerance
- **WHEN** user calls `(query-shape :my-box :where (list (edge-p) (edge-along 0 0 1 :angle-deg 5)))`
- **THEN** the system returns edges whose direction is within 5 degrees of +Z

### Requirement: radius-around predicate
The system SHALL provide a `radius-around` predicate that filters circular edges whose radius is within a tolerance of a given value.

#### Scenario: Edges with specific radius
- **WHEN** user calls `(query-shape :my-cylinder :where (list (edge-p) (radius-around 5)))`
- **THEN** the system returns circular edges with radius 5mm

#### Scenario: Edges within radius range
- **WHEN** user calls `(query-shape :my-shape :where (list (edge-p) (radius-around 5 :tolerance 0.5)))`
- **THEN** the system returns circular edges with radius between 4.5mm and 5.5mm

### Requirement: Convenience accessor functions
The system SHALL provide convenience functions `top-face`, `bottom-face`, `longest-edge`, `largest-face`, `shortest-edge`, `smallest-face` that apply common query patterns to a designator.

#### Scenario: top-face returns the highest face
- **WHEN** user calls `(top-face :my-box)`
- **THEN** the system returns the planar face with the highest center Z coordinate (normal aligned with +Z)

#### Scenario: bottom-face returns the lowest face
- **WHEN** user calls `(bottom-face :my-box)`
- **THEN** the system returns the planar face with the lowest center Z coordinate (normal aligned with -Z)

#### Scenario: longest-edge returns the longest edge
- **WHEN** user calls `(longest-edge :my-box)`
- **THEN** the system returns the edge with the maximum 3D length

#### Scenario: Convenience on non-box shapes
- **WHEN** user calls `(top-face (make-cylinder 5 20))`
- **THEN** the system returns the top planar face of the cylinder (the one with the highest Z center)
