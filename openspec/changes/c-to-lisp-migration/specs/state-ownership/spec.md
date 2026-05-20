## MODIFIED Requirements

### Requirement: Shape state ownership

**Before:** Shape state was stored in both C++ (ViewerState::shapes map +
ViewerState::shape_names vector) and Lisp (*displayed-models* hash table).
viewer_put_shape/viewer_remove_shape/viewer_clear updated both.

**After:** *displayed-models* is the single source of truth. The C++ shape
map is kept as a transient rendering cache (name → Handle(AIS_Shape)) for
name-based OCCT operations, but no logic depends on its contents.

#### Scenario: Display shape from Lisp

- **WHEN** `(display "box" (make-box 10 20 30))` is called
- **THEN** a `:display` message SHALL be pushed to *viewer-queue*
- **WHEN** the queue is drained
- **THEN** `%viewer-put-shape` SHALL be called with the shape pointer and name
- **THEN** the C++ side SHALL create an AIS_Shape, display it in context,
        cache it in the shape map, and call FitAll
- **THEN** *displayed-models* SHALL be updated with the shape

#### Scenario: Remove shape from Lisp

- **WHEN** `(undisplay "box")` is called
- **THEN** the name SHALL be removed from *displayed-models*
- **THEN** `%viewer-remove-shape` SHALL be called
- **THEN** the C++ side SHALL erase the shape from context and remove it
        from the cache map

#### Scenario: Clear all shapes from Lisp

- **WHEN** `(clear-all)` is called
- **THEN** *displayed-models* SHALL be cleared
- **THEN** `%viewer-clear` SHALL be called
- **THEN** the C++ side SHALL remove all shapes from context and clear
        the cache map

### Requirement: Visibility state ownership

#### Scenario: Toggle grid from REPL

- **WHEN** `(toggle-grid)` is called from the REPL
- **THEN** the Lisp variable *grid-visible* SHALL toggle
- **THEN** `%viewer-show-grid` SHALL be called with the new state

#### Scenario: Toggle axis from REPL

- **WHEN** `(toggle-axis)` is called from the REPL
- **THEN** the Lisp variable *axis-visible* SHALL toggle
- **THEN** `%viewer-show-axis` SHALL be called with the new state

### Requirement: No duplicate state

- The C++ ViewerState SHALL NOT contain shape_names, grid_visible,
  axis_visible, eval_callback, queue, timer, or processing_modal
- The C++ ViewerState SHALL contain only: window, widget, context,
  shapes (cache map), file_op_callback, drain_callback, running
