## ADDED Requirements

### Requirement: defmodel macro
The system SHALL provide a `defmodel` macro that defines a parametric model and generates a function with keyword arguments for each parameter. The macro supports optional metadata clauses (`:color`, `:name`, `:layer`) before the body.

#### Scenario: defmodel with keyword function
- **WHEN** `(defmodel my-box (:w :d :h) (make-box (param :w) (param :d) (param :h)))`
- **THEN** `(my-box :w 10 :d 20 :h 30)` evaluates the body with local param overrides and returns a shape
- **AND** calling `(my-box)` without keyword args uses global `*params*` values

#### Scenario: defmodel with metadata
- **WHEN** `(defmodel my-box (:w) (:color :blue :name "Box") (make-box (param :w) 20 30))`
- **THEN** `(my-box :w 10)` returns the shape and metadata is accessible via `model-color` and `model-display-name`

### Requirement: Reference another model
The `model-ref` function SHALL return the cached shape of a named model, creating a DAG dependency edge. An error is signaled if the model is not found.

#### Scenario: Reference existing model
- **WHEN** model `part-a` is defined, and `(model-ref 'part-a)` is called
- **THEN** the cached shape of `part-a` is returned

#### Scenario: Reference missing model
- **WHEN** `(model-ref 'nonexistent)` is called and `nonexistent` is not in the registry
- **THEN** an error is signaled

### Requirement: Metadata accessors
The system SHALL provide `model-color`, `model-display-name`, and `model-layer` to read metadata from a named model.

#### Scenario: Access metadata
- **WHEN** `(defmodel my-box (:w) (:color :red :name "My Box" :layer "Parts") (make-box (param :w) 20 30))`
- **THEN** `(model-color 'my-box)` returns `:red`
- **AND** `(model-display-name 'my-box)` returns `"My Box"`
- **AND** `(model-layer 'my-box)` returns `"Parts"`

### Requirement: Help function
The system SHALL provide a `help` function that prints a summary of all available modeling and DSL functions.

#### Scenario: Print help
- **WHEN** `(help)` is called
- **THEN** a formatted list of available functions and their signatures is printed to stdout

### Requirement: `set-param!` returns the value
`set-param!` SHALL return the newly set value after propagation.

#### Scenario: set-param! return value
- **WHEN** `(set-param! :w 30)`
- **THEN** the return value is `30`

### Requirement: `set-params!` returns the param plist
`set-params!` SHALL return the full `*params*` plist after batch update and propagation.

#### Scenario: set-params! return value
- **WHEN** `(set-params! :w 30 :d 20)`
- **THEN** the return value is the updated `*params*` plist
