## ADDED Requirements

### Requirement: Scene tree supports multi-select

The `SceneTreePanel` SHALL set `QTreeWidget::setSelectionMode` to `QAbstractItemView::ExtendedSelection`. This enables native Qt multi-select: click selects single, Ctrl+click toggles an item, Shift+click selects a range.

#### Scenario: click selects one item

- **WHEN** the user clicks on a tree item
- **THEN** that item SHALL become selected
- **AND** all other items SHALL become deselected

#### Scenario: Ctrl+click toggles item

- **WHEN** the user Ctrl+clicks on a deselected tree item
- **THEN** that item SHALL become selected
- **AND** previously selected items SHALL remain selected

#### Scenario: Shift+click selects range

- **WHEN** the user clicks item "A", then Shift+clicks item "C"
- **THEN** items "A", "B", and "C" SHALL all be selected

### Requirement: Tree selection change fires Lisp callback

The `SceneTreePanel` SHALL connect `QTreeWidget::itemSelectionChanged` to a C++ slot `onTreeSelectionChanged`. This slot SHALL collect the names of all selected tree items, build a `const char**` array, and fire the registered `tree_selection_callback` to Lisp.

#### Scenario: tree selection fires callback

- **WHEN** the user selects an item in the scene tree
- **THEN** `tree_selection_callback` SHALL be invoked with the selected names
- **AND** the callback SHALL NOT fire during programmatic tree updates (signals blocked)

### Requirement: Lisp tree callback updates `*selected*` and syncs OCCT

The Lisp `%on-tree-selection` callback SHALL:
1. Update `*selected*` to match the tree's selection
2. Call `sync-selection-to-occt` to sync the OCCT context

#### Scenario: tree selection updates Lisp state

- **WHEN** the Lisp callback receives `["box1", "box2"]` from the tree
- **THEN** `*selected*` SHALL contain `"box1"` and `"box2"`
- **AND** `sync-selection-to-occt` SHALL be called

### Requirement: Bidirectional sync with 3D view

When selection changes in the 3D view, the scene tree SHALL update to reflect the new selection. When selection changes in the tree, the 3D view SHALL update to highlight the selected shapes.

#### Scenario: 3D view selection updates tree

- **WHEN** the user selects a shape in the 3D viewport
- **THEN** `OnSelectionChanged` SHALL call `SceneTreePanel::syncSelection` with the set of selected names
- **AND** the corresponding tree item SHALL become selected
- **AND** tree signals SHALL be blocked during this update

#### Scenario: tree selection updates 3D view

- **WHEN** the user selects a tree item
- **THEN** the tree callback fires → Lisp updates `*selected*` → `sync-selection-to-occt` SHALL clear and set OCCT selection
- **AND** the 3D view SHALL highlight the selected shape

#### Scenario: no infinite loop on bidirectional sync

- **WHEN** the 3D view selection changes
- **THEN** tree sync SHALL block signals
- **AND** the tree callback SHALL NOT fire
- **AND** `OnSelectionChanged` SHALL NOT be called again

### Requirement: Tree selection survival across shape sync

When `viewer_sync_shapes` is called (e.g., after a boolean operation that changes geometry), the scene tree items are recreated/updated. The selection state of items SHALL be preserved from `*selected*`.

#### Scenario: selection persists after shape update

- **WHEN** a shape with changed geometry is synced
- **AND** it was selected before the sync
- **THEN** after the sync, `syncSelection` SHALL be called as part of the sync process
- **AND** the shape's tree item SHALL remain selected
