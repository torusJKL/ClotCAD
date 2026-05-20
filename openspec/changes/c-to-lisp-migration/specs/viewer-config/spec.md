## MODIFIED Requirements

### Requirement: Viewer initialization

**Before:** ViewerWidget::initializeGL() called setupAxis() and setupGrid()
during the first OpenGL initialization. The trihedron and grid were created
with hardcoded parameters (wireframe mode, 50px size, lower-left corner,
rectangular grid with lines).

**After:** ViewerWidget::initializeGL() only wraps the OpenGL context and
creates the V3d_Viewer/V3d_View/AIS_InteractiveContext. Trihedron creation,
grid activation, and all viewer configuration happen from Lisp via the
initialize-viewer function.

#### Scenario: First initialization

- **WHEN** the QOpenGLWidget is first shown and initializeGL() is called
- **THEN** the GL context SHALL be wrapped into OCCT's V3d_View
- **THEN** the V3d_Viewer, V3d_View, and AIS_InteractiveContext SHALL
        be created with default parameters
- **THEN** setupAxis() SHALL NOT be called
- **THEN** setupGrid() SHALL NOT be called
- **THEN** myFirstInit SHALL NOT be tracked

#### Scenario: Post-startup viewer configuration

- **WHEN** `start-viewer` is called
- **THEN** after `%viewer-show` succeeds and before `%viewer-run` blocks
- **THEN** `initialize-viewer` SHALL be called
- **THEN** `initialize-viewer` SHALL call:
  - `%viewer-show-axis` to display the trihedron
  - `%viewer-show-grid` to activate the rectangular grid
  - `%viewer-set-antialiasing` to enable AA

#### Scenario: Runtime configuration from REPL

- **WHEN** `(show-axis nil)` is called from the REPL
- **THEN** the axis trihedron SHALL be hidden
- **WHEN** `(show-axis t)` is called
- **THEN** the axis trihedron SHALL be displayed

### Requirement: Viewer widget cleanup

- ViewerWidget.h SHALL remove: setupAxis(), setupGrid(), myAxis,
  myFirstInit
- The AIS_Trihedron creation code SHALL be removed from viewer_widget.cpp
