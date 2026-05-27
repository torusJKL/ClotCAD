## ADDED Requirements

### Requirement: Help shows minimal quick-start with pointers to browse/doc

The `help` function SHALL display a minimal overview that teaches users how to discover the API themselves via `browse` and `doc`, rather than listing every available function. It SHALL include:
- A one-line project description
- Pointers to `(browse)` and `(doc ...)` as the primary discovery tools
- A quick-start example that gives immediate visual feedback in the 3D viewer
- Brief reference for the most essential commands (primitives, booleans, defmodel)

#### Scenario: Help displays minimal quick-start

- **WHEN** the user evaluates `(help)`
- **THEN** the output SHALL include the text "ClotCAD" and the project description
- **AND** the output SHALL include references to `(browse)` and `(doc ...)` as discovery tools
- **AND** the output SHALL include a quick-start example using `(make-box 10 10 10)` or equivalent that provides immediate visual feedback

#### Scenario: Help does not list every function

- **WHEN** the user evaluates `(help)`
- **THEN** the output SHALL NOT list individual functions beyond the quick-start examples
- **AND** the output SHALL direct users to `(browse)` for the full catalog
