## ADDED Requirements

### Requirement: ViewCube visibility control from Lisp

The Lisp API SHALL provide functions to show, hide, and toggle the ViewCube, matching the grid/axis pattern.

#### Scenario: Show ViewCube
- **WHEN** `(show-viewcube t)` is called
- **THEN** the ViewCube SHALL become visible
- **THEN** `*viewcube-visible*` SHALL be set to T

#### Scenario: Hide ViewCube
- **WHEN** `(show-viewcube nil)` is called
- **THEN** the ViewCube SHALL be hidden
- **THEN** `*viewcube-visible*` SHALL be set to NIL

#### Scenario: Toggle ViewCube
- **WHEN** `(toggle-viewcube)` is called
- **THEN** the ViewCube visibility SHALL be inverted
- **THEN** `*viewcube-visible*` SHALL reflect the new state

### Requirement: Programmatic view control from Lisp

The Lisp API SHALL provide a `set-view` function that accepts orientation keywords.

#### Scenario: Set view to top
- **WHEN** `(set-view :top)` is called
- **THEN** the camera SHALL orient to look in the +X direction (top view in Y-up)
- **THEN** the ViewCube SHALL update its highlighted face
- **THEN** `*current-view*` SHALL be set to :TOP

#### Scenario: Set view to bottom
- **WHEN** `(set-view :bottom)` is called
- **THEN** the camera SHALL orient to look in the -X direction
- **THEN** `*current-view*` SHALL be set to :BOTTOM

#### Scenario: Set view to front
- **WHEN** `(set-view :front)` is called
- **THEN** the camera SHALL orient to look in the +Y direction
- **THEN** `*current-view*` SHALL be set to :FRONT

#### Scenario: Set view to back
- **WHEN** `(set-view :back)` is called
- **THEN** the camera SHALL orient to look in the -Y direction
- **THEN** `*current-view*` SHALL be set to :BACK

#### Scenario: Set view to left
- **WHEN** `(set-view :left)` is called
- **THEN** the camera SHALL orient to look in the +Z direction
- **THEN** `*current-view*` SHALL be set to :LEFT

#### Scenario: Set view to right
- **WHEN** `(set-view :right)` is called
- **THEN** the camera SHALL orient to look in the -Z direction
- **THEN** `*current-view*` SHALL be set to :RIGHT

#### Scenario: Set view to isometric
- **WHEN** `(set-view :iso)` is called
- **THEN** the camera SHALL orient to an isometric perspective

### Requirement: Current view retrieval from Lisp

The Lisp API SHALL provide a `current-view` function that returns the current orientation.

#### Scenario: Get current view after orbit
- **WHEN** the user orbits the camera arbitrarily
- **THEN** `(current-view)` SHALL return a keyword representing the current orientation (or NIL if non-standard)

#### Scenario: Get current view after set-view
- **WHEN** `(set-view :top)` has been called
- **THEN** `(current-view)` SHALL return :TOP

#### Scenario: Get current view after ViewCube click
- **WHEN** user clicks the "Front" face of the ViewCube and animation completes
- **THEN** `(current-view)` SHALL return :FRONT

### Requirement: ViewCube orientation callback

The Lisp system SHALL register a callback that fires when the ViewCube animation completes, updating `*current-view*`.

#### Scenario: Callback registered at startup
- **WHEN** `register-viewer-callbacks` is called
- **THEN** a ViewCube orientation callback SHALL be registered

#### Scenario: ViewCube click updates *current-view*
- **WHEN** user clicks a ViewCube face and animation completes
- **THEN** `*current-view*` SHALL be updated to match the new orientation

### Requirement: ViewCube theme integration

The theme system SHALL support ViewCube styling through palette entries.

#### Scenario: ViewCube colors in palette
- **WHEN** `apply-theme` is called
- **THEN** the ViewCube face color SHALL be set from the `:viewcube-color` palette entry
- **THEN** the ViewCube text color SHALL be set from the `:viewcube-text-color` palette entry
- **THEN** the ViewCube inner color SHALL be set from the `:viewcube-inner-color` palette entry
- **THEN** the ViewCube transparency SHALL be set from the `:viewcube-transparency` palette entry

#### Scenario: Dark palette includes viewcube entries
- **WHEN** `%dark-palette` is called
- **THEN** the returned alist SHALL include `:viewcube-color`, `:viewcube-text-color`, `:viewcube-inner-color`, and `:viewcube-transparency` keys

#### Scenario: Light palette includes viewcube entries
- **WHEN** `%light-palette` is called
- **THEN** the returned alist SHALL include the same viewcube keys with appropriate light-theme values

### Requirement: ViewCube font height control from Lisp (DPR-aware)

The Lisp API SHALL provide `(set-viewcube-font-height height)` that sets the ViewCube label font height in logical pixels. The C++ implementation SHALL multiply the value by the device pixel ratio.

#### Scenario: Set ViewCube font height
- **WHEN** `(set-viewcube-font-height 20)` is called on a standard display
- **THEN** the ViewCube labels SHALL render at 20 device pixels

#### Scenario: ViewCube font height in theme palette
- **WHEN** a theme palette contains `(:viewcube-font-height . "20")`
- **THEN** after `apply-theme` the ViewCube font height SHALL be set to 20 logical pixels

#### Scenario: Dark palette includes font-height
- **WHEN** `%dark-palette` is called
- **THEN** the returned alist SHALL include `:viewcube-font-height` with a default value

### Requirement: Trihedron font size control from Lisp (DPR-aware)

The Lisp API SHALL provide `(set-trihedron-font-size size)` that sets the trihedron's axis label font size in logical pixels. The C++ implementation SHALL multiply the value by the device pixel ratio.

#### Scenario: Set trihedron font size
- **WHEN** `(set-trihedron-font-size 18)` is called on a standard display
- **THEN** the trihedron X, Y, Z labels SHALL render at 18 device pixels each

#### Scenario: Trihedron font size in theme palette
- **WHEN** a theme palette contains `(:trihedron-font-size . "18")`
- **THEN** after `apply-theme` the trihedron font size SHALL be set to 18 logical pixels

#### Scenario: Dark palette includes trihedron-font-size
- **WHEN** `%dark-palette` is called
- **THEN** the returned alist SHALL include `:trihedron-font-size` with a default value

### Requirement: DPR-aware initialization at startup

`initialize-viewer` SHALL query the device pixel ratio at startup and apply scaled defaults for ViewCube size, ViewCube font height, and trihedron font size.

#### Scenario: DPR-scaled defaults applied at startup
- **WHEN** `initialize-viewer` is called
- **THEN** `%viewer-get-device-pixel-ratio` SHALL be queried
- **THEN** ViewCube size SHALL be set to `70 × dpr`
- **THEN** ViewCube font height SHALL be set to `16 × dpr`
- **THEN** trihedron font size SHALL be set to `16 × dpr`
