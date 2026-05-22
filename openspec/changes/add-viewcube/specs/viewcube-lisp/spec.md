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
