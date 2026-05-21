## ADDED Requirements

### Requirement: resolve-shape accepts string designators

`resolve-shape` SHALL accept a string argument and look it up directly in
`*displayed-models*`. If the string names an existing entry, the shape value
MUST be returned. If it does not, an error MUST be signaled.

#### Scenario: String lookup finds displayed shape

- **WHEN** `*displayed-models*` contains an entry with key `"box2"` whose
  shape is a box object
- **THEN** `(resolve-shape "box2")` returns that box object

#### Scenario: String lookup errors on unknown name

- **WHEN** `*displayed-models*` has no entry with key `"nonexistent"`
- **THEN** `(resolve-shape "nonexistent")` signals an error

### Requirement: Shape operations accept string designators

All wrapper functions that call `resolve-shape` (`cut`, `fuse`, `common`,
`section`, `translate`, `rotate`, `make-prism`, `make-revol`, `make-compound`,
`make-part`, `write-step`, `write-stl`) SHALL work with string designators
via the updated `resolve-shape`.

#### Scenario: cut with string operands

- **WHEN** `*displayed-models*` contains `"s"` → sphere and `"box2"` → box
- **THEN** `(cut "s" "box2")` returns the boolean difference shape, equivalent to `(cut :s :box2)`

#### Scenario: translate with string shape

- **WHEN** `*displayed-models*` contains `"box2"` → box
- **THEN** `(translate "box2" 10 20 30)` translates the box shape
