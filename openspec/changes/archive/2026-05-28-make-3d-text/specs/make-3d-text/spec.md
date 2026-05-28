## ADDED Requirements

### Requirement: make-3d-text creates extruded 3D text in one call

The system SHALL provide a function `make-3d-text` in the `clotcad` package that creates an extruded 3D text shape from a string, accepting the following keyword arguments:

- `:font` — optional font name string; when nil, try fallback chain
- `:size` — font size in model units (default 10)
- `:thickness` — extrusion depth (default 5)
- `:h-align` — horizontal alignment `:left`, `:center`, `:right` (default `:center`)
- `:v-align` — vertical alignment `:bottom`, `:center`, `:top`, `:top-first-line` (default `:center`)
- `:plane` — placement specification (default `:xz`)

The function SHALL return a `shape` object suitable for `display`, `def`, `show`, `hide`, `write-step`, `write-stl`, and all boolean/transform operations.

#### Scenario: No arguments creates XZ-plane text with centered alignment

- **WHEN** `(make-3d-text "Hello")` is called
- **THEN** it SHALL return a non-nil shape with text reading left-to-right along +X, up along +Z, extrusion along +Y

#### Scenario: XY plane produces text in XY plane

- **WHEN** `(make-3d-text "Label" :plane :xy)` is called
- **THEN** it SHALL return text reading left-to-right along +X, up along +Y, extrusion along +Z

#### Scenario: YZ plane produces text in YZ plane

- **WHEN** `(make-3d-text "Label" :plane :yz)` is called
- **THEN** it SHALL return text reading along +Y, up along +Z, extrusion along +X

#### Scenario: Custom font is passed through

- **WHEN** `(make-3d-text "Hello" :font "Arial" :size 20)` is called
- **THEN** the text SHALL be rendered in Arial font at 20 model units (or signal an error if Arial is not available)

#### Scenario: Face plane extracts frame from face geometry

- **WHEN** `(make-3d-text "Hello" :plane some-face)` is called with a face shape
- **THEN** the text SHALL be placed on a plane derived from the face's surface at its UV midpoint, with text reading along the face's U-direction, up along the face's V-direction

#### Scenario: Frame plane extracts axes directly

- **WHEN** `(make-3d-text "Hello" :plane some-frame)` is called with a `frame` instance
- **THEN** the text SHALL use the frame's Z-axis as normal and X-axis as reading direction

#### Scenario: Non-nil shape returned is usable with display

- **WHEN** `(display :my-label (make-3d-text "Label"))` is evaluated
- **THEN** the shape SHALL appear in the 3D viewer

### Requirement: Automatic font fallback with error reporting

When `:font` is nil, the function SHALL try these font names in order:
1. `"sans-serif"`
2. `"Arial"`
3. `"DejaVu Sans"`
4. `"Liberation Sans"`
5. `"FreeSans"`

If none of the fallback fonts can be loaded, the function SHALL call `list-available-fonts` and signal an error that includes the available font names.

#### Scenario: Fallback succeeds with a common font

- **WHEN** `(make-3d-text "Hello")` is called on a system with at least one of the fallback fonts
- **THEN** the function SHALL succeed and return a non-nil shape without errors

#### Scenario: All fallbacks fail produces informative error

- **WHEN** `(make-3d-text "Hello")` is called on a system with NO installable fonts
- **THEN** the function SHALL signal an error that includes the output of `list-available-fonts`

### Requirement: Docstrings and cheatsheet compliance

The function SHALL have a complete docstring listing all arguments, defaults, and at least one usage example.

The cheatsheet SHALL include `make-3d-text` under a new section labeled "3D Text" with its signature: `make-3d-text(string, ..options)`.

#### Scenario: Docstring lists all keyword arguments

- **WHEN** `(doc 'make-3d-text)` is evaluated
- **THEN** the output SHALL mention `:font`, `:size`, `:thickness`, `:h-align`, `:v-align`, and `:plane`
