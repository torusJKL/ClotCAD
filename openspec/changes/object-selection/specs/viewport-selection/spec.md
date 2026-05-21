## ADDED Requirements

### Requirement: 3D viewport object selection with ReplaceExtra scheme

The system SHALL enable object selection in the 3D viewport via OCCT's `AIS_InteractiveContext`. Each displayed shape SHALL have its selection mode activated (mode 0 = whole shape). The `ViewerWidget` SHALL override `UpdateMouseClick` to use the selection scheme stored in `ViewerState::mouse_schemes` (defaulting to `ReplaceExtra` for no modifier, `Add` for Ctrl, `XOR` for Shift).

#### Scenario: click selects a shape

- **WHEN** the user clicks on a visible shape in the 3D viewport
- **THEN** the shape SHALL become selected (highlighted) in the viewport
- **AND** any previously selected shape SHALL remain selected if the new click is on the same shape (ReplaceExtra behavior)

#### Scenario: Ctrl+click adds to selection

- **WHEN** the user Ctrl+clicks on a different shape
- **THEN** that shape SHALL be added to the existing selection set
- **AND** the previously selected shape SHALL remain selected

#### Scenario: Shift+click toggles selection

- **WHEN** the user Shift+clicks on a selected shape
- **THEN** that shape SHALL be removed from the selection

### Requirement: OnSelectionChanged fires Lisp callback

The `ViewerWidget` SHALL override `OnSelectionChanged` to:
1. Iterate the OCCT context's selected objects
2. Look up names via the `ViewerState::obj_to_name` reverse map
3. Update scene tree selection (with `blockSignals`)
4. Fire the registered `selection_callback` to Lisp

#### Scenario: 3D view selection triggers Lisp callback

- **WHEN** the user selects a shape in the 3D viewport
- **THEN** `selection_callback` SHALL be invoked
- **AND** the Lisp callback SHALL update `*selected*` by iterating `*displayed-models*` and calling `ais-is-selected`

#### Scenario: tree does not re-emit during programmatic sync

- **WHEN** `OnSelectionChanged` updates the scene tree
- **THEN** the tree SHALL block signals during the update
- **AND** `itemSelectionChanged` SHALL NOT fire as a result of the programmatic update

### Requirement: Hover detection enabled

The system SHALL enable OCCT's default dynamic highlighting on mouse move. Shapes SHALL pre-highlight when the cursor hovers over them (OCCT default behavior via `AIS_ViewController::handleDynamicHighlight`).

#### Scenario: shape highlights on hover

- **WHEN** the user moves the mouse over a shape in the 3D viewport
- **THEN** the shape SHALL change color/brightness to indicate it is under the cursor

#### Scenario: hover highlight clears on move away

- **WHEN** the user moves the mouse away from a previously hovered shape
- **THEN** the shape SHALL return to its normal appearance

### Requirement: Selection mode activated on shape display

When `viewer_sync_shapes` creates an `AIS_Shape`, the system SHALL call `context->Activate(shape, 0)` to enable selection for that shape.

#### Scenario: shape is selectable after display

- **WHEN** a shape is displayed via `(display :box ...)`
- **THEN** clicking on it in the 3D viewport SHALL select it

#### Scenario: shape is not selectable after removal

- **WHEN** a shape is removed via `(undisplay :box)`
- **THEN** clicking on its former location SHALL NOT select any shape

### Requirement: Reverse map for name lookup

The `ViewerState` SHALL maintain a `std::map<Standard_Transient*, std::string>` mapping each `AIS_Shape`'s raw pointer to its name string. This map SHALL be populated when shapes are created and cleared when shapes are removed in `viewer_sync_shapes`.

#### Scenario: reverse map entry created on sync

- **WHEN** `viewer_sync_shapes` processes a new shape
- **THEN** `obj_to_name[ais_shape.get()]` SHALL be set to the shape's name

#### Scenario: reverse map entry removed on sync

- **WHEN** `viewer_sync_shapes` processes a shape removal
- **THEN** the corresponding `obj_to_name` entry SHALL be erased
