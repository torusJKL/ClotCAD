## ADDED Requirements

### Requirement: Scene tree dock widget

The viewer SHALL provide a dockable scene tree panel on the left side of the window showing all displayed shapes with visibility checkboxes.

#### Scenario: Scene tree visible by default
- **WHEN** the viewer starts
- **THEN** the scene tree panel SHALL be visible as a QDockWidget on the left side
- **THEN** the scene tree panel SHALL be approximately 200px wide

#### Scenario: Shape appears in tree
- **WHEN** `viewer_put_shape()` is called
- **THEN** the shape name SHALL appear in the scene tree with its checkbox checked

#### Scenario: Toggle visibility via checkbox
- **WHEN** user unchecks a shape's checkbox in the scene tree
- **THEN** `context->Erase(shape, false)` SHALL be called
- **THEN** the shape SHALL be hidden in the 3D viewport
- **WHEN** user re-checks the checkbox
- **THEN** `context->Display(shape, false)` SHALL be called
- **THEN** the shape SHALL reappear in the 3D viewport

#### Scenario: Shape removed from tree
- **WHEN** `viewer_remove_shape()` is called
- **THEN** the shape SHALL be removed from the scene tree
- **WHEN** `viewer_clear()` is called
- **THEN** all shapes SHALL be removed from the scene tree

#### Scenario: Scene tree panel toggle
- **WHEN** user toggles the scene tree panel via the View menu
- **THEN** the scene tree panel SHALL show or hide

### Requirement: Scene tree API

The scene tree SHALL support querying and modifying shape state through the C API.

#### Scenario: Query shape count
- **WHEN** `viewer_get_shape_count()` is called
- **THEN** it SHALL return the number of currently displayed shapes

#### Scenario: Query shape name
- **WHEN** `viewer_get_shape_name(idx)` is called
- **THEN** it SHALL return the name of the shape at the given index

#### Scenario: Query shape visibility
- **WHEN** `viewer_is_shape_visible(name)` is called
- **THEN** it SHALL return 1 if the shape is displayed, 0 if erased

#### Scenario: Set shape visibility
- **WHEN** `viewer_set_shape_visible(name, 0)` is called
- **THEN** the shape SHALL be erased from the viewport
- **WHEN** `viewer_set_shape_visible(name, 1)` is called
- **THEN** the shape SHALL be displayed in the viewport
