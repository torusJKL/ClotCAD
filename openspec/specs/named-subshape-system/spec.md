# named-subshape-system Specification

## Purpose
TBD - created by archiving change named-subshape-system. Update Purpose after archive.
## Requirements
### Requirement: name-subshape registers a named query on a model
The system SHALL provide `(name-subshape model name &rest query-args)` that stores a named query on the model. The name is a keyword or symbol (without the model prefix). The query args are the `:where` and `:coordinate-system` arguments.

#### Scenario: Register a named face
- **WHEN** user calls `(name-subshape :my-box :top-face :where (list (face-p) (normal-along 0 0 1) (max-by #'z-center)))`
- **THEN** the model `:my-box` stores the query under the name `:top-face`

#### Scenario: Named subshape is resolved on access
- **WHEN** user calls `(face-ref :my-box :top-face)`
- **THEN** the system re-evaluates the stored query on the current shape of `:my-box` and returns the matching subshape

#### Scenario: name-subshape works with strings
- **WHEN** user calls `(name-subshape "my-box" "top-edge" :where (list (edge-p) (edge-along 0 0 1) (max-by #'edge-length)))`
- **THEN** the model is found case-insensitively and the query is stored

### Requirement: face-ref resolves a named subshape
The system SHALL provide `(face-ref model name)` that resolves a previously named subshape on a model and returns the face. Signals an error if the name is not registered.

#### Scenario: face-ref returns the face
- **WHEN** user calls `(face-ref :my-box :top-face)`
- **THEN** the system returns the face subshape matching the stored query

#### Scenario: face-ref errors on unknown name
- **WHEN** user calls `(face-ref :my-box :nonexistent)`
- **THEN** the system signals an error that the name is not found

### Requirement: edge-ref resolves a named edge subshape
The system SHALL provide `(edge-ref model name)` analogous to `face-ref` but expecting the result to be an edge.

#### Scenario: edge-ref returns the edge
- **WHEN** user calls `(edge-ref :my-box :longest)`
- **THEN** the system returns the edge subshape matching the stored query

### Requirement: vertex-ref resolves a named vertex subshape
The system SHALL provide `(vertex-ref model name)` analogous to `face-ref` but expecting the result to be a vertex.

#### Scenario: vertex-ref returns the vertex
- **WHEN** user calls `(vertex-ref :my-box :origin-corner)`
- **THEN** the system returns the vertex subshape matching the stored query

### Requirement: Compound symbol resolution for named subshapes
The system SHALL support compound symbols `:model/name` as designators in all ClotCAD functions that accept shape designators. The system splits on `/`, resolves the model, and resolves the named subshape.

#### Scenario: Compound symbol in fillet-edge
- **WHEN** user calls `(fillet-edge :my-box :my-box/top-edge 3.0)`
- **THEN** `:my-box/top-edge` resolves to the named edge on `:my-box` and `:my-box` resolves to the model's cached shape

#### Scenario: Compound symbol resolves model and name
- **WHEN** user calls `(face-named :my-box/top-face)`
- **THEN** the system resolves to the same face as `(face-ref :my-box :top-face)`

### Requirement: list-named-subshapes returns all names on a model
The system SHALL provide `(list-named-subshapes model)` that returns a list of registered subshape names for a model.

#### Scenario: List names after registering
- **WHEN** user registers two subshapes and calls `(list-named-subshapes :my-box)`
- **THEN** the system returns `(:top-face :longest-edge)`

### Requirement: remove-named-subshape removes a named reference
The system SHALL provide `(remove-named-subshape model name)` that removes a named subshape registration.

#### Scenario: Remove a named subshape
- **WHEN** user calls `(remove-named-subshape :my-box :top-face)` then `(face-ref :my-box :top-face)`
- **THEN** the system signals an error that the name is not found

### Requirement: Scene Tree displays named subshapes
The system SHALL integrate with the existing Scene Tree display to show named subshapes as children of their parent model. Named subshapes appear grayed/indented under the model name.

#### Scenario: Named subshapes appear in tree
- **WHEN** user registers `:top-face` on `:my-box` and the Scene Tree is visible
- **THEN** the tree shows:
  ```
  ⬡ :my-box
    ⬡ :my-box/top-face
  ```

#### Scenario: Scene tree updates on new names
- **WHEN** user registers a new named subshape
- **THEN** the Scene Tree updates to include the new entry without manual refresh

### Requirement: Named subshapes are selectable in the 3D view
The system SHALL support selecting/highlighting a named subshape in the 3D view when clicked in the Scene Tree.

#### Scenario: Click in Scene Tree selects the subshape
- **WHEN** user clicks on `:my-box/top-face` in the Scene Tree
- **THEN** the corresponding face is highlighted (selected) in the 3D viewport

