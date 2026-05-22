## ADDED Requirements

### Requirement: Users can define named shapes

Users SHALL be able to associate a symbol with a shape using the `def` macro without displaying it. The `def` macro SHALL store the shape in `*displayed-models*` with `visible=nil` and `show-in-tree` controlled by `*show-defs-in-tree*`. The `def` macro SHALL return the shape value.

#### Scenario: Define a shape without displaying
- **WHEN** user evaluates `(def :s (make-sphere 20))`
- **THEN** `:s` is associated with the sphere shape in `*displayed-models*`
- **THEN** the sphere is NOT visible in the 3D view
- **THEN** the sphere is either shown or hidden in the Scene Tree depending on `*show-defs-in-tree*`
- **THEN** the sphere shape is returned

#### Scenario: Define outputs a value
- **WHEN** user evaluates `(def :s (make-sphere 20))` in REPL
- **THEN** the REPL prints the shape object

### Requirement: Users can resolve symbols to shapes

The system SHALL provide a `resolve-shape` function that accepts a shape designator (symbol, string, or shape object) and returns a shape object. For symbols, the resolution order SHALL be: `*displayed-models*` (stringified symbol), then DAG `*model-registry*` (symbol). For shape objects, the function SHALL pass them through unchanged.

#### Scenario: Resolve a symbol to a displayed shape
- **WHEN** user evaluates `(resolve-shape :s)` after `(display :s (make-sphere 20))`
- **THEN** the sphere shape is returned

#### Scenario: Resolve a symbol to a def-ined shape
- **WHEN** user evaluates `(resolve-shape :s)` after `(def :s (make-sphere 20))`
- **THEN** the sphere shape is returned

#### Scenario: Resolve a shape object passes through
- **WHEN** user evaluates `(let ((s (make-sphere 20))) (resolve-shape s))`
- **THEN** the same shape object is returned

#### Scenario: Resolve unknown symbol signals error
- **WHEN** user evaluates `(resolve-shape :unknown)`
- **THEN** an error is signaled

### Requirement: Boolean operations auto-resolve symbols

The system SHALL provide `cut`, `fuse`, `common`, and `section` as wrapper functions in the viewer layer. Each SHALL accept both shape objects and symbols as arguments, resolving symbols via `resolve-shape`, and delegating to the `cl-occt` implementation.

#### Scenario: Cut accepts symbols
- **WHEN** user evaluates `(cut :s :b)` where `:s` and `:b` are defined or displayed
- **THEN** the boolean cut operation is performed on the resolved shapes

#### Scenario: Cut accepts mixed symbols and raw shapes
- **WHEN** user evaluates `(cut :s (make-box 10 20 30))`
- **THEN** `:s` is resolved and the cut is performed

### Requirement: Transform operations auto-resolve

The system SHALL provide `translate` and `rotate` wrapper functions that resolve the first argument as a shape designator.

#### Scenario: Translate accepts a symbol
- **WHEN** user evaluates `(translate :s 10 0 0)`
- **THEN** `:s` is resolved and the translation is applied

### Requirement: Derived shape operations auto-resolve

The system SHALL provide `make-prism` and `make-revol` wrapper functions that resolve their first argument as a shape designator.

#### Scenario: Make-prism accepts a symbol
- **WHEN** user evaluates `(make-prism :s 0 0 10)`
- **THEN** `:s` is resolved and the prism is created

### Requirement: Compound operations auto-resolve

The system SHALL provide `make-compound` wrapper that resolves each element in the list.

#### Scenario: Make-compound accepts symbols
- **WHEN** user evaluates `(make-compound (list :s :b))`
- **THEN** each element is resolved and the compound is created

### Requirement: Assembly operations auto-resolve

The system SHALL provide `make-part` wrapper that resolves its shape argument.

#### Scenario: Make-part accepts a symbol
- **WHEN** user evaluates `(make-part :s :name "My Part")`
- **THEN** `:s` is resolved and the assembly part is created

### Requirement: I/O operations auto-resolve

The system SHALL provide `write-step` and `write-stl` wrapper functions that resolve their shape argument.

#### Scenario: Write-step accepts a symbol
- **WHEN** user evaluates `(write-step :s "out.step")`
- **THEN** `:s` is resolved and the shape is exported
