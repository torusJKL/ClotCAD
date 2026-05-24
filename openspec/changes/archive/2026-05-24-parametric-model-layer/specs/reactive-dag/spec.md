## ADDED Requirements

### Requirement: Define a parametric model
The system SHALL allow defining a named parametric model via `defmodel`. A model has a name, a body function, parameter keys, dependencies on other models, and a cached shape. Models are registered in a global `*model-registry*`.

#### Scenario: Define a model with explicit parameter list
- **WHEN** user writes `(defmodel my-box (:w :d :h) (make-box (param :w) (param :d) (param :h)))`
- **THEN** a model named `my-box` is registered in `*model-registry*`
- **AND** the model has `param-keys` = `(:w :d :h)`
- **AND** calling `(my-box)` evaluates the body and returns a shape

#### Scenario: Define a model with auto-detected parameters
- **WHEN** user writes `(defmodel my-box () (make-box (param :w) (param :d) (param :h)))`
- **THEN** the model's `param-keys` are auto-detected as `(:w :d :h)` from `param` calls in the body

#### Scenario: Model dependency tracking
- **WHEN** user writes `(defmodel assembly () (fuse (model-ref part-a) (model-ref part-b)))`
- **THEN** the model has `model-deps` = `(part-a part-b)`
- **AND** `part-a` and `part-b` have `assembly` listed in their `dependents`

### Requirement: Set a parameter and propagate
The system SHALL provide `set-param!` to update a global parameter value, mark dependent models dirty, and trigger re-evaluation in dependency order.

#### Scenario: Set a parameter triggers re-evaluation
- **WHEN** `(set-param! :w 30)` is called after defining a model that depends on `:w`
- **THEN** the global `*params*` plist has `:w` mapped to `30`
- **AND** all models depending on `:w` are re-evaluated via `propagate-changes`

#### Scenario: Batch set multiple parameters
- **WHEN** `(set-params! :w 30 :d 20)` is called
- **THEN** both `:w` and `:d` are updated in `*params*`
- **AND** propagation runs once for all changed keys

### Requirement: Topological evaluation order
The system SHALL evaluate dirty models in topological order (dependencies before dependents), with cycle detection.

#### Scenario: Simple dependency order
- **WHEN** model `B` depends on model `A`, and `(set-param! :x 10)` marks both dirty
- **THEN** model `A` is re-evaluated before model `B`

#### Scenario: Cycle detection
- **WHEN** model `A` depends on `B` and `B` depends on `A`
- **THEN** `propagate-changes` signals an error with a cycle message

### Requirement: Nil propagation
When a model's body returns nil (e.g., degenerate geometry), the cached shape SHALL be nil and dependent models receive nil via `model-ref`.

#### Scenario: Nil shape propagates
- **WHEN** model `A` returns nil, and model `B` uses `(model-ref A)`
- **THEN** `B`'s evaluation receives nil for `(model-ref A)`

### Requirement: Global parameter store
The system SHALL provide `*params*`, a plist of global parameter key-value pairs accessible via `param`.

#### Scenario: Read a global parameter
- **WHEN** `*params*` is `(:w 30 :d 20)` and user calls `(param :w)`
- **THEN** the return value is `30`

#### Scenario: Missing parameter signals error
- **WHEN** `(param :nonexistent)` is called and `:nonexistent` is not in `*params*`
- **THEN** an error is signaled

### Requirement: Local parameter scope
The system SHALL provide `with-params` to temporarily override parameters for the duration of a body, using `*local-params*`.

#### Scenario: Local override
- **WHEN** `*params*` has `(:w 30)` and user writes `(with-params (:w 50) (param :w))`
- **THEN** the return value is `50`

### Requirement: Model redefinition
Defining a model with the same name as an existing model SHALL replace it, including updating dependent models' `dependents` lists.

#### Scenario: Redefine model
- **WHEN** `(defmodel my-box (:w) (make-box (param :w) 20 30))` is called after a previous definition of `my-box`
- **THEN** the old model is unregistered and replaced
- **AND** dependent models' dependents lists are updated
