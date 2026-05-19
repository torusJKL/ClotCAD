## ADDED Requirements

### Requirement: Qt6 window and event loop

The application SHALL create a QApplication and run its event loop on the main thread. The window SHALL be a QMainWindow subclass.

#### Scenario: Window creation
- **WHEN** `viewer_create()` is called
- **THEN** a QApplication SHALL be initialized (if not already)
- **THEN** a QMainWindow SHALL be created with the given title and initial size

#### Scenario: Event loop runs
- **WHEN** `viewer_run()` is called
- **THEN** `QApplication::exec()` SHALL be called, blocking the calling thread

#### Scenario: Graceful shutdown
- **WHEN** `viewer_quit()` is called from any thread
- **THEN** `QApplication::quit()` SHALL be called
- **THEN** `QApplication::exec()` SHALL return

### Requirement: 3D viewport with OCCT AIS rendering

The application SHALL display a 3D viewport using QOpenGLWidget, rendering OCCT AIS presentations via OpenGl_GraphicDriver and V3d_Viewer.

#### Scenario: OpenGL widget created
- **WHEN** the main window is created
- **THEN** the central widget SHALL be a QOpenGLWidget subclass

#### Scenario: OCCT graphics driver initialized
- **WHEN** `initializeGL()` is called on the QOpenGLWidget
- **THEN** an `OpenGl_GraphicDriver` SHALL be created
- **THEN** the driver's GL context SHALL wrap the Qt-managed GL context via `OpenGl_Context::Init()`
- **THEN** a `V3d_Viewer` SHALL be created with default lights enabled
- **THEN** an `AIS_InteractiveContext` SHALL be created for the viewer
- **THEN** a `V3d_View` SHALL be created and bound to a virtual window (`OcctNeutralWindow`)

#### Scenario: Scene is rendered
- **WHEN** `paintGL()` is called
- **THEN** the Qt framebuffer object SHALL be wrapped for OCCT via `OcctGlTools::InitializeGlFbo()`
- **THEN** GL state SHALL be reset before OCCT rendering
- **THEN** `FlushViewEvents()` SHALL be called to process queued input and redraw the scene
- **THEN** GL state SHALL be reset after OCCT rendering

#### Scenario: Viewport resizes
- **WHEN** the window is resized
- **THEN** `resizeGL()` SHALL call `myView->MustBeResized()`

### Requirement: AIS_ViewController camera control

The QOpenGLWidget SHALL inherit from `AIS_ViewController` and forward mouse events for orbit, pan, and zoom.

#### Scenario: Orbit with left mouse button
- **WHEN** user presses left mouse button and drags in the viewport
- **THEN** the view SHALL orbit around the center point

#### Scenario: Pan with middle mouse button
- **WHEN** user presses middle mouse button and drags
- **THEN** the view SHALL pan

#### Scenario: Zoom with scroll wheel
- **WHEN** user scrolls the mouse wheel
- **THEN** the view SHALL zoom in/out

#### Scenario: Zoom with right mouse button
- **WHEN** user presses right mouse button and drags up/down
- **THEN** the view SHALL zoom in/out

#### Scenario: Animation frames
- **WHEN** `AIS_ViewController::handleViewRedraw()` is called with animation pending
- **THEN** `update()` SHALL be called to request the next paint frame

### Requirement: AIS_Trihedron axis helper

The 3D viewport SHALL display a trihedron axis indicator in the lower-left corner using `AIS_Trihedron` with transform persistence.

#### Scenario: Axis shown by default
- **WHEN** the viewer starts
- **THEN** an axis helper SHALL be visible in the lower-left corner of the viewport

#### Scenario: Axis labels
- **WHEN** the axis is visible
- **THEN** the X arrow SHALL be red, Y green, Z blue
- **THEN** arrows SHALL be labeled "X", "Y", "Z"

#### Scenario: Axis persists across camera movement
- **WHEN** the user orbits the view
- **THEN** the axis SHALL remain in the lower-left corner of the viewport (transform persistence)

### Requirement: Rectangular grid

The viewer SHALL display a rectangular grid on the ground plane (Y=0) using `V3d_Viewer::ActivateGrid`.

#### Scenario: Grid shown by default
- **WHEN** the viewer starts
- **THEN** a rectangular grid SHALL be visible on the ground plane

#### Scenario: Grid appearance
- **WHEN** the grid is visible
- **THEN** grid lines SHALL be a neutral gray color
- **THEN** the grid SHALL be positioned at Y=0

### Requirement: Event-driven rendering (0% CPU idle)

The viewer SHALL only redraw when events (mouse, keyboard, shape changes) occur.

#### Scenario: Idle CPU
- **WHEN** the viewer is open with no user input and no pending shape changes
- **THEN** Qt's event loop SHALL block consuming negligible CPU

#### Scenario: Redraw on mouse event
- **WHEN** user moves the mouse in the viewport
- **THEN** the scene SHALL be redrawn

#### Scenario: Redraw on shape change
- **WHEN** a shape change is posted from the Lisp worker thread
- **THEN** a `QEvent::User` SHALL be posted to the main thread
- **THEN** the queue SHALL be drained
- **THEN** `update()` SHALL schedule a redraw

### Requirement: Anti-aliased rendering

The viewer SHALL support MSAA anti-aliasing for smooth edge rendering.

#### Scenario: Anti-aliasing enabled by default
- **WHEN** the viewer starts
- **THEN** MSAA with 4 samples SHALL be enabled in `V3d_View::ChangeRenderingParams()`

#### Scenario: Anti-aliasing toggle
- **WHEN** `viewer_set_antialiasing(0)` is called
- **THEN** MSAA SHALL be disabled (0 samples)
- **WHEN** `viewer_set_antialiasing(1)` is called
- **THEN** MSAA SHALL be re-enabled with 4 samples
