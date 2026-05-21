## REVISED: Menus restored

### Requirement: Menu bar restored

**Before (migration):** The menu bar was stripped to an empty bar with
no menus. All file operations were REPL-driven.

**After (restored):** The menu bar contains File (Import STEP/STL,
Export STEP/STL) and View (REPL, Scene Tree, Axis, Grid toggles) menus.
All state management stays in Lisp — C++ provides only the widget shell
and QFileDialog calls.

#### Scenario: Window creation

- **WHEN** viewer_create() is called
- **THEN** a QMainWindow SHALL be created with a menu bar
- **THEN** the menu bar SHALL contain a File menu with Import/Export
        STEP/STL actions
- **THEN** the menu bar SHALL contain a View menu with REPL, Scene Tree,
        Axis, and Grid toggle actions
- **THEN** File menu actions SHALL open QFileDialog and dispatch to
        file_op_callback
- **THEN** View > Axis and View > Grid toggles SHALL call
        viewer_show_axis / viewer_show_grid

### Requirement: Menu ↔ Lisp state sync

- **WHEN** the user toggles Axis or Grid via the View menu
- **THEN** viewer_show_axis / viewer_show_grid SHALL update the OCCT
        scene AND the menu checkbox
- **WHEN** the user calls (toggle-axis) or (toggle-grid) from Lisp
- **THEN** the Lisp function SHALL query the actual C++ state via
        %viewer-is-axis-visible / %viewer-is-grid-visible before
        toggling
- **THEN** axis/grid visibility SHALL be consistent between menu and
        Lisp in both directions

### Requirement: REPL dock toggle from Lisp

- **WHEN** the user calls (toggle-repl) or (show-repl nil) from Lisp
- **THEN** viewer_show_dock SHALL update the REPL dock visibility and
        sync the View > REPL menu checkbox
- **WHEN** the user calls (toggle-scene-tree) or (show-scene-tree nil)
- **THEN** viewer_show_dock SHALL update the Scene Tree dock visibility
        and sync the View > Scene Tree menu checkbox

### Requirement: Scene tree panel kept

- **WHEN** the window is created
- **THEN** the SceneTreePanel dock widget SHALL be created (unchanged)
- **THEN** the scene tree SHALL be populated via the existing C API
        (viewer_put_shape calls dock->addShape internally)

### Requirement: File operations via both menu and REPL

- **WHEN** the user selects File > Import/Export from the menu
- **THEN** a QFileDialog SHALL open (C++ side)
- **THEN** the selected path SHALL be dispatched via file_op_callback
        to the Lisp handle-file-op handler
- **WHEN** the user runs (read-step "path") from the REPL
- **THEN** file operations can also be performed directly without the
        menu dialog

### Requirement: Status bar simplified

- **WHEN** the window is created
- **THEN** the status bar labels (shape count, FPS) SHALL be created but
        SHALL NOT be updated by C++
- **THEN** updateShapeCount / updateFps SHALL be kept as callable
        methods but are no longer called from the timer

### Requirement: No modal rendering guard

- **WHEN** paintGL() is called
- **THEN** the myProcessingModal guard SHALL NOT exist
- **THEN** rendering SHALL proceed without checking the modal flag
- **THEN** the ViewerWidget::myProcessingModal field SHALL be removed
        (the render timer is now in Lisp, not C++, so file dialogs
        triggered from menu actions on the Qt thread don't race with
        a C++ timer)

### Requirement: documentation updated

The following SHALL be updated to reflect the restored UI:

- **README.md**: Interface table includes REPL Panel and Menu Bar rows;
  layout diagram includes REPL panel; files list includes repl_panel.h/.cpp;
  usage section describes both in-window REPL and SLIME workflow;
  export section describes menu-based export
- **AGENTS.md**: Architecture section updated to mention restored REPL
  panel and menu wiring
