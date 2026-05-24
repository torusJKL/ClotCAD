## ADDED Requirements

### Requirement: Specify color on a model
The `defmodel` macro SHALL accept an optional `:color` metadata clause in the body. The color is preserved through re-evaluation and accessible via `model-color`.

#### Scenario: Model with color metadata
- **WHEN** user writes `(defmodel my-box (:w :d :h) (:color :blue) (make-box (param :w) (param :d) (param :h)))`
- **THEN** `(model-color 'my-box)` returns a color value (e.g., RGB list or keyword)

#### Scenario: Color preserved after re-evaluation
- **WHEN** `(set-param! :w 30)` triggers re-evaluation of the above model
- **THEN** `(model-color 'my-box)` still returns the same color

### Requirement: Specify name on a model
The `defmodel` macro SHALL accept an optional `:name` metadata clause for a human-readable display name, accessible via `model-display-name`.

#### Scenario: Model with name metadata
- **WHEN** user writes `(defmodel my-box (:w) (:name "My Box") (make-box (param :w) 20 30))`
- **THEN** `(model-display-name 'my-box)` returns `"My Box"`

### Requirement: Specify layer on a model
The `defmodel` macro SHALL accept an optional `:layer` metadata clause, accessible via `model-layer`.

#### Scenario: Model with layer metadata
- **WHEN** user writes `(defmodel my-box (:w) (:layer "Layer1") (make-box (param :w) 20 30))`
- **THEN** `(model-layer 'my-box)` returns `"Layer1"`

### Requirement: No metadata by default
A model defined without metadata clauses SHALL have nil values for color, display-name, and layer.

#### Scenario: Model without metadata
- **WHEN** user writes `(defmodel my-box (:w) (make-box (param :w) 20 30))`
- **THEN** `(model-color 'my-box)` returns nil
- **AND** `(model-display-name 'my-box)` returns nil
- **AND** `(model-layer 'my-box)` returns nil
