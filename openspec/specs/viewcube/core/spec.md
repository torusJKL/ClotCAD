## ADDED Requirements

### Requirement: ViewCube display

The application SHALL display an AIS_ViewCube in the top-right corner of the 3D viewport using transform persistence.

#### Scenario: ViewCube shown by default
- **WHEN** the viewer starts
- **THEN** a ViewCube SHALL be visible in the top-right corner of the viewport
- **THEN** the ViewCube SHALL have default OCCT styling (white faces, gray edges, black text)

#### Scenario: ViewCube persists across camera movement
- **WHEN** the user orbits the view
- **THEN** the ViewCube SHALL remain in the top-right corner of the viewport (transform persistence)

#### Scenario: ViewCube orientation reflects current view
- **WHEN** the user orbits to a different view direction
- **THEN** the ViewCube SHALL update its highlighted face to match the current camera direction

### Requirement: ViewCube click to orient

Clicking a face, edge, or vertex of the ViewCube SHALL smoothly animate the camera to the corresponding orientation.

#### Scenario: Clicking a face orients to that view
- **WHEN** user clicks the "Top" face of the ViewCube
- **THEN** the camera SHALL smoothly animate to look from above (Y+ direction)

#### Scenario: Clicking an edge orients to a 45-degree view
- **WHEN** user clicks an edge of the ViewCube
- **THEN** the camera SHALL smoothly animate to a 45-degree angle between the two adjacent faces

#### Scenario: Clicking a vertex orients to a corner view
- **WHEN** user clicks a vertex of the ViewCube
- **THEN** the camera SHALL smoothly animate to a three-quarters perspective

### Requirement: ViewCube visibility toggle (C API)

The C API SHALL provide functions to show, hide, and query ViewCube visibility, following the same pattern as axis/grid.

#### Scenario: Hide ViewCube via API
- **WHEN** `viewer_show_viewcube(vwr, 0)` is called
- **THEN** the ViewCube SHALL be erased from the viewport
- **THEN** `viewer_is_viewcube_visible(vwr)` SHALL return 0

#### Scenario: Show ViewCube via API
- **WHEN** `viewer_show_viewcube(vwr, 1)` is called
- **THEN** the ViewCube SHALL be displayed in the viewport
- **THEN** `viewer_is_viewcube_visible(vwr)` SHALL return 1

#### Scenario: ViewCube visibility syncs with menu action
- **WHEN** `viewer_show_viewcube(vwr, 1)` or `viewer_show_viewcube(vwr, 0)` is called
- **THEN** the View menu checkbox SHALL be checked or unchecked accordingly

### Requirement: Programmatic view set (C API)

The C API SHALL provide a function to set the camera view direction programmatically.

#### Scenario: Set view to top
- **WHEN** `viewer_set_view(vwr, V3d_Xpos)` is called
- **THEN** the camera SHALL immediately orient to look in the +X direction (top view in Y-up)
- **THEN** the ViewCube highlighted face SHALL update to match

#### Scenario: Set view to front
- **WHEN** `viewer_set_view(vwr, V3d_Ypos)` is called
- **THEN** the camera SHALL immediately orient to look in the +Y direction (front view)

#### Scenario: Set view to right
- **WHEN** `viewer_set_view(vwr, V3d_Zpos)` is called
- **THEN** the camera SHALL immediately orient to look in the +Z direction (right view)

### Requirement: Current view retrieval (C API)

The C API SHALL provide a function to retrieve the current camera view orientation.

#### Scenario: Get current orientation
- **WHEN** `viewer_get_view_orientation(vwr)` is called after any camera movement
- **THEN** it SHALL return an integer matching the current `V3d_TypeOfOrientation` value

#### Scenario: Orientation after ViewCube click
- **WHEN** user clicks a ViewCube face and the animation completes
- **THEN** `viewer_get_view_orientation(vwr)` SHALL return the orientation of that face

### Requirement: ViewCube orientation change callback

The C API SHALL provide a callback registration mechanism that fires when the ViewCube animation completes.

#### Scenario: Callback fires after ViewCube animation
- **WHEN** user clicks a ViewCube face and the animation finishes
- **THEN** the registered callback SHALL be invoked with the new orientation as an integer
- **THEN** the callback SHALL be called on the Qt main thread

#### Scenario: No callback fires for programmatic view change
- **WHEN** `viewer_set_view(vwr, ...)` is called from Lisp
- **THEN** no orientation callback SHALL fire

### Requirement: ViewCube theming (C API)

The C API SHALL provide functions to style the ViewCube appearance.

#### Scenario: Set ViewCube box color
- **WHEN** `viewer_set_viewcube_color(vwr, r, g, b)` is called
- **THEN** the ViewCube face color SHALL change to the specified RGB values

#### Scenario: Set ViewCube text color
- **WHEN** `viewer_set_viewcube_text_color(vwr, r, g, b)` is called
- **THEN** the ViewCube label text color SHALL change to the specified RGB values

#### Scenario: Set ViewCube inner (back-face) color
- **WHEN** `viewer_set_viewcube_inner_color(vwr, r, g, b)` is called
- **THEN** the ViewCube inner (back) face color SHALL change to the specified RGB values

#### Scenario: Set ViewCube transparency
- **WHEN** `viewer_set_viewcube_transparency(vwr, t)` is called
- **THEN** the ViewCube transparency SHALL be set to the specified value (0.0 = opaque, 1.0 = fully transparent)

#### Scenario: Set ViewCube size
- **WHEN** `viewer_set_viewcube_size(vwr, s)` is called
- **THEN** the ViewCube size SHALL be set to the specified value in pixels

### Requirement: ViewCube font height C API (DPR-aware)

The C API SHALL provide `viewer_set_viewcube_font_height(vwr, height)` which sets the font height of ViewCube labels (both side labels and embedded X/Y/Z axis labels). The implementation SHALL multiply the input value by the widget's device pixel ratio.

#### Scenario: Set ViewCube font height on standard display
- **WHEN** `viewer_set_viewcube_font_height(vwr, 16)` is called on a display with DPR=1.0
- **THEN** the ViewCube side labels and axis labels SHALL render at 16 device pixels

#### Scenario: Set ViewCube font height on Retina display
- **WHEN** `viewer_set_viewcube_font_height(vwr, 16)` is called on a display with DPR=2.0
- **THEN** the ViewCube side labels and axis labels SHALL render at 32 device pixels

#### Scenario: ViewCube font height also scales embedded axis labels
- **WHEN** `viewer_set_viewcube_font_height(vwr, 20)` is called
- **THEN** the ViewCube's embedded X, Y, Z axis labels SHALL be scaled to the same pixel height as the side labels

### Requirement: ViewCube scales by DPR at creation

`viewer_create` SHALL multiply the ViewCube's default size (70), font height (16), and corner offset (100, 100) by the widget's device pixel ratio.

#### Scenario: ViewCube default size on standard display
- **WHEN** the viewer creates the ViewCube on a display with DPR=1.0
- **THEN** SetSize(70) and SetFontHeight(16) SHALL be called

#### Scenario: ViewCube default size on Retina display
- **WHEN** the viewer creates the ViewCube on a display with DPR=2.0
- **THEN** SetSize(140) and SetFontHeight(32) SHALL be called

### Requirement: Trihedron font size C API (DPR-aware)

The C API SHALL provide `viewer_set_trihedron_font_size(vwr, size)` which sets the font size of the trihedron's axis labels (X/Y/Z). The implementation SHALL multiply the input value by the widget's device pixel ratio.

#### Scenario: Set trihedron font size on standard display
- **WHEN** `viewer_set_trihedron_font_size(vwr, 16)` is called on a display with DPR=1.0
- **THEN** the trihedron X, Y, Z labels SHALL render at 16 device pixels each

#### Scenario: Set trihedron font size on Retina display
- **WHEN** `viewer_set_trihedron_font_size(vwr, 16)` is called on a display with DPR=2.0
- **THEN** the trihedron X, Y, Z labels SHALL render at 32 device pixels each

### Requirement: Trihedron scales by DPR at creation

`viewer_show_axis` SHALL multiply the trihedron's default size (50) and corner offset (60, 60) by the widget's device pixel ratio.

#### Scenario: Trihedron default size on standard display
- **WHEN** the trihedron is created on a display with DPR=1.0
- **THEN** SetSize(50) SHALL be called

#### Scenario: Trihedron default size on Retina display
- **WHEN** the trihedron is created on a display with DPR=2.0
- **THEN** SetSize(100) SHALL be called

### Requirement: C API to query device pixel ratio

The C API SHALL provide `viewer_get_device_pixel_ratio(vwr)` that returns the widget's device pixel ratio as a double.

#### Scenario: Query DPR at startup
- **WHEN** Lisp calls `(%viewer-get-device-pixel-ratio vwr)` during initialization
- **THEN** it SHALL return a value ≥ 1.0 (1.0 on standard displays, 2.0 on Retina)
