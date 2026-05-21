## ADDED Requirements

### Requirement: Users can show def-ined shapes

The system SHALL provide a `show` function that takes one or more symbols and makes their associated shapes visible in the 3D view. The `show` function SHALL look up symbols in `*displayed-models*` (by stringified name) and set `visible=t`. The `show` function SHALL NOT modify the `show-in-tree` flag. The `show` function SHALL trigger a sync. If a symbol is not in `*displayed-models*`, an error SHALL be signaled.

#### Scenario: Show a def-ined shape
- **WHEN** user evaluates `(show :s)` after `(def :s (make-sphere 20))`
- **THEN** the sphere becomes visible in the 3D view
- **THEN** the Scene Tree checkbox for `:s` becomes checked

#### Scenario: Show multiple shapes
- **WHEN** user evaluates `(show :s :b)`
- **THEN** both shapes become visible

#### Scenario: Show unknown symbol signals error
- **WHEN** user evaluates `(show :unknown)`
- **THEN** an error is signaled

### Requirement: Users can hide shapes

The system SHALL provide a `hide` function that takes one or more symbols and makes their associated shapes invisible in the 3D view. The `hide` function SHALL set `visible=nil`. The `hide` function SHALL trigger a sync. If a symbol is not in `*displayed-models*`, an error SHALL be signaled.

#### Scenario: Hide a displayed shape
- **WHEN** user evaluates `(hide :s)` after `(show :s)`
- **THEN** the sphere becomes invisible in the 3D view
- **THEN** the Scene Tree checkbox for `:s` becomes unchecked

#### Scenario: Hide unknown symbol signals error
- **WHEN** user evaluates `(hide :unknown)`
- **THEN** an error is signaled

### Requirement: Users can toggle shape visibility

The system SHALL provide a `toggle` function that takes one or more symbols and flips their `visible` flag. The `toggle` function SHALL trigger a sync. If a symbol is not in `*displayed-models*`, an error SHALL be signaled.

#### Scenario: Toggle a visible shape
- **WHEN** user evaluates `(toggle :s)` while `:s` is visible
- **THEN** `:s` becomes invisible

#### Scenario: Toggle an invisible shape
- **WHEN** user evaluates `(toggle :s)` while `:s` is invisible
- **THEN** `:s` becomes visible

### Requirement: Users can toggle def-ined shapes in the Scene Tree

The system SHALL provide a `show-defs` function that takes a boolean and sets all def-ined shapes' `show-in-tree` flag to that value. The function SHALL update `*show-defs-in-tree*` and retroactively apply to all existing def-ined shapes. The system SHALL provide a `toggle-defs` function that flips `*show-defs-in-tree*` and applies the new value to all def-ined shapes.

#### Scenario: Show-defs hides def-ined shapes from tree
- **WHEN** user evaluates `(show-defs nil)`
- **THEN** all def-ined shapes are hidden from the Scene Tree
- **THEN** `*show-defs-in-tree*` is `nil`

#### Scenario: Show-defs shows def-ined shapes in tree
- **WHEN** user evaluates `(show-defs t)`
- **THEN** all def-ined shapes appear in the Scene Tree
- **THEN** `*show-defs-in-tree*` is `t`

#### Scenario: Toggle-defs flips and batch-applies
- **WHEN** user evaluates `(toggle-defs)` twice
- **THEN** `*show-defs-in-tree*` returns to its original value
- **THEN** all def-ined shapes have the same show-in-tree state (all from the first toggle, then all from the second)

### Requirement: Scene Tree checkbox is bidirectional

When the user clicks a checkbox in the Scene Tree, the C++ side SHALL update the Lisp `*displayed-models*` entry's `visible` flag. When `show`/`hide`/`toggle` update the `visible` flag, the C++ side SHALL update the Scene Tree checkbox.

#### Scenario: User checks a box in the tree
- **WHEN** user clicks the checkbox for `:s` from unchecked to checked
- **THEN** the shape becomes visible in the 3D view
- **THEN** `(second (gethash "S" *displayed-models*))` is `t`

#### Scenario: Lisp hides a shape, tree updates
- **WHEN** user evaluates `(hide :s)`
- **THEN** the Scene Tree checkbox for `:s` becomes unchecked
