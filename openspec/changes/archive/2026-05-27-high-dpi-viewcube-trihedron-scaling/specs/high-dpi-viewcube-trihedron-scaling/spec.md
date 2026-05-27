## ADDED Requirements

### Requirement: ViewCube font height is user-configurable and DPR-aware

The system SHALL expose a function `set-viewcube-font-height` that sets the font height of the ViewCube's text labels (side labels FRONT/BACK/TOP/BOTTOM/LEFT/RIGHT and axis labels X/Y/Z). The function SHALL accept a positive number in logical pixels. The C++ implementation SHALL multiply the input value by the widget's device pixel ratio so the rendered font is physically consistent across displays.

#### Scenario: Set ViewCube font height on 1080p (DPR=1.0)

- **WHEN** user calls `(set-viewcube-font-height 20)`
- **THEN** the ViewCube labels render at 20 device pixels

#### Scenario: Set ViewCube font height on 4K Retina (DPR=2.0)

- **WHEN** user calls `(set-viewcube-font-height 20)`
- **THEN** the ViewCube labels render at 40 device pixels

#### Scenario: Default ViewCube font height at startup on 1080p

- **WHEN** the viewer starts on a display with device pixel ratio 1.0
- **THEN** the ViewCube font height SHALL default to 16 logical pixels

#### Scenario: Default ViewCube font height at startup on 4K Retina

- **WHEN** the viewer starts on a display with device pixel ratio 2.0
- **THEN** the ViewCube font height SHALL default to 32 device pixels (16 logical × 2)

#### Scenario: ViewCube font height in theme palette

- **WHEN** a theme palette contains `(:viewcube-font-height . "20")`
- **THEN** after `apply-theme` the ViewCube font height SHALL be 20 logical pixels (scaled by DPR at render time)

### Requirement: Trihedron font size is user-configurable and DPR-aware

The system SHALL expose a function `set-trihedron-font-size` that sets the font size of the trihedron's axis labels (X/Y/Z). The function SHALL accept a positive number in logical pixels. The C++ implementation SHALL multiply the input value by the widget's device pixel ratio.

#### Scenario: Set trihedron font size on 1080p (DPR=1.0)

- **WHEN** user calls `(set-trihedron-font-size 18)`
- **THEN** the trihedron X, Y, Z labels render at 18 device pixels each

#### Scenario: Set trihedron font size on 4K Retina (DPR=2.0)

- **WHEN** user calls `(set-trihedron-font-size 18)`
- **THEN** the trihedron X, Y, Z labels render at 36 device pixels each

#### Scenario: Default trihedron font size at startup

- **WHEN** the viewer starts
- **THEN** the trihedron font size SHALL default to 16 logical pixels (scaled by DPR)

#### Scenario: Trihedron font size in theme palette

- **WHEN** a theme palette contains `(:trihedron-font-size . "18")`
- **THEN** after `apply-theme` the trihedron font size SHALL be 18 logical pixels (scaled by DPR at render time)

### Requirement: ViewCube scales by DPR at creation time

The C++ `viewer_create` function SHALL multiply the ViewCube's default size (70), font height (16), and corner offset (100, 100) by the widget's device pixel ratio.

#### Scenario: ViewCube default size on 1080p

- **WHEN** the viewer creates the ViewCube on a display with DPR=1.0
- **THEN** SetSize(70) and SetFontHeight(16) SHALL be called

#### Scenario: ViewCube default size on 4K Retina

- **WHEN** the viewer creates the ViewCube on a display with DPR=2.0
- **THEN** SetSize(140) and SetFontHeight(32) SHALL be called

### Requirement: Trihedron scales by DPR at creation time

The C++ `viewer_show_axis` function SHALL multiply the trihedron's default size (50) and corner offset (60, 60) by the widget's device pixel ratio.

#### Scenario: Trihedron default size on 1080p

- **WHEN** the trihedron is created on a display with DPR=1.0
- **THEN** SetSize(50) SHALL be called

#### Scenario: Trihedron default size on 4K Retina

- **WHEN** the trihedron is created on a display with DPR=2.0
- **THEN** SetSize(100) SHALL be called

### Requirement: Lisp can query device pixel ratio

The system SHALL expose a CFFI function `%viewer-get-device-pixel-ratio` that returns the widget's device pixel ratio as a double-float.

#### Scenario: Query DPR at startup

- **WHEN** `initialize-viewer` calls `(%viewer-get-device-pixel-ratio vwr)`
- **THEN** it SHALL return a value ≥ 1.0 (1.0 on standard displays, 2.0 on Retina)
