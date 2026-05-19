## ADDED Requirements

### Requirement: Menu bar with import/export

The viewer SHALL provide a menu bar with File and View menus, including STEP and STL import/export via native QFileDialog.

#### Scenario: File menu
- **WHEN** the viewer starts
- **THEN** the menu bar SHALL have a File menu with Import and Export submenus
- **THEN** Import SHALL have STEP and STL items
- **THEN** Export SHALL have STEP and STL items

#### Scenario: View menu
- **WHEN** the viewer starts
- **THEN** the View menu SHALL have toggle items for REPL, Scene Tree, Axis, and Grid
- **THEN** each toggle item SHALL show a checkmark when the panel/feature is visible

#### Scenario: Import STEP via file dialog
- **WHEN** user clicks File → Import → STEP
- **THEN** a native QFileDialog SHALL open for file selection
- **THEN** the filter SHALL be "STEP Files (*.step *.STEP)"
- **WHEN** user selects a file
- **THEN** `file_op_callback(path, OP_IMPORT_STEP)` SHALL be called
- **THEN** the imported shape SHALL appear in the viewport

#### Scenario: Export STEP via file dialog
- **WHEN** user clicks File → Export → STEP and at least one shape is displayed
- **THEN** a native QFileDialog SHALL open for save location
- **THEN** the filter SHALL be "STEP Files (*.step *.STEP)"
- **WHEN** user selects a save path
- **THEN** `file_op_callback(path, OP_EXPORT_STEP)` SHALL be called
- **WHEN** no shapes are displayed
- **THEN** the Export menu items SHALL be disabled (grayed out)

#### Scenario: Import STL via file dialog
- **WHEN** user clicks File → Import → STL
- **THEN** a native QFileDialog SHALL open for file selection
- **THEN** the filter SHALL be "STL Files (*.stl *.STL)"
- **WHEN** user selects a file
- **THEN** `file_op_callback(path, OP_IMPORT_STL)` SHALL be called

#### Scenario: Export STL via file dialog
- **WHEN** user clicks File → Export → STL and at least one shape is displayed
- **THEN** a native QFileDialog SHALL open for save location
- **THEN** the filter SHALL be "STL Files (*.stl *.STL)"
- **WHEN** user selects a save path
- **THEN** `file_op_callback(path, OP_EXPORT_STL)` SHALL be called

### Requirement: Status bar

The viewer SHALL display a status bar at the bottom of the window showing shape count and FPS.

#### Scenario: Status bar visible
- **WHEN** the viewer starts
- **THEN** a QStatusBar SHALL be visible at the bottom of the main window

#### Scenario: Shape count display
- **WHEN** shapes are displayed
- **THEN** the status bar SHALL show "Displaying N shapes"
- **WHEN** all shapes are removed
- **THEN** the status bar SHALL show "Displaying 0 shapes"

#### Scenario: FPS display
- **WHEN** the viewer is running
- **THEN** the status bar SHALL show approximate FPS
- **THEN** the FPS value SHALL be updated once per second
