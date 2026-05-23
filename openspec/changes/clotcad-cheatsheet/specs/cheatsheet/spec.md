## ADDED Requirements

### Requirement: Content covers core ClotCAD API

The cheatsheet SHALL include function signatures for the following categories, clearly separated:

- 3D Primitives: `make-box`, `make-cylinder`, `make-sphere`, `make-cone`, `make-torus`
- Sweeps: `make-prism`, `make-revol`
- Boolean Operations: `cut`, `fuse`, `common`, `section`
- Transformations: `translate`, `rotate`
- 2D Geometry: `make-pnt2d`, `make-vec2d`, `make-dir2d`, `make-line2d`, `make-circle2d`, `make-edge`, `make-edge-3d`, `make-circle-edge`, `make-circular-arc`, `make-wire`, `make-face`, `make-face-on-plane`
- Display Management: `display`, `undisplay`, `clear-all`, `def`, `show`, `hide`, `toggle`, `show-defs`, `toggle-defs`, `resolve-shape`
- Selection: `select`, `deselect`, `clear-selection`, `selected-shapes`, `apply-selection-schemes`
- View Controls: `set-view`, `current-view`, `fit-view`, `set-view-aa`, `show-grid`, `toggle-grid`, `show-axis`, `toggle-axis`, `show-viewcube`, `toggle-viewcube`, `show-viewcube-axes`, `toggle-viewcube-axes`
- Dock Panels: `show-repl`, `toggle-repl`, `show-scene-tree`, `toggle-scene-tree`
- Theme: `apply-theme`, `theme-dark`, `theme-light`, `theme-auto`, `set-accent`, `set-font-size`
- Parametric DSL: `defmodel`, `param`, `model-ref`, `model-color`, `model-display-name`, `set-param!`, `set-params!`, `with-params`
- Compounds & Assemblies: `make-compound`, `add-to-compound`, `make-part`, `make-assembly`
- File I/O: `write-step`, `read-step`, `write-stl`, `read-stl`
- REPL: `cancel-import`, `replay-speed`, `result-export`, `export-repl-history`, `set-repl-history-key`, `set-repl-submit-key`

#### Scenario: All required functions are present in the rendered PDF

- **WHEN** a reader searches the cheatsheet for any function listed above
- **THEN** the function signature SHALL appear under its category section

### Requirement: Parametric DSL section includes syntax-highlighted examples

The Parametric DSL section SHALL contain at least three code examples using Typst's `lisp` syntax highlighting:

1. A parameterized model definition using `defmodel` and `param`
2. A model referencing another model via `model-ref`
3. A batch parameter update using `set-params!`

Other sections SHALL show only bare function signatures with no examples or descriptions (OpenSCAD style).

#### Scenario: DSL examples are syntax highlighted

- **WHEN** the cheatsheet PDF is inspected
- **THEN** the DSL examples SHALL appear in a code block with Lisp syntax coloring (keywords, strings, numbers distinguished)

#### Scenario: Non-DSL sections have no examples

- **WHEN** inspecting non-DSL sections
- **THEN** they SHALL contain only function signatures with no code examples or prose descriptions

### Requirement: Document is multi-page with readable typography

The cheatsheet SHALL render on 4-5 A4 pages using the boxed-sheet template with:

- Monospace font: Cousine (fallback Liberation Mono)
- Body font size: 7.5pt
- Number of columns: 3
- Column gutter: 6pt
- Line skip: 8pt
- A 6-color palette cycling through sections (blue, green, orange, purple, teal, red)
- Section headings as colored blocks (boxed-sheet `= Heading` style)

#### Scenario: Layout matches specification

- **WHEN** the compiled PDF is measured
- **THEN** font size SHALL be 7.5pt, columns SHALL be 3, and page count SHALL be 4-5

### Requirement: Version is auto-injected from git

The cheatsheet SHALL display the ClotCAD version in its header/title, derived from `git describe --tags --long` at compile time:

- If the current commit is a tagged commit: show the tag name (e.g., `v0.1.0`)
- If not on a tag: show tag name + commit count (e.g., `v0.1.0-16`)
- Passed via `typst compile --input version=...` and read via `sys.inputs.version`
- Fallback: if git describe fails, show `dev`

#### Scenario: Version appears in document header

- **WHEN** the cheatsheet is compiled via `just cheatsheet`
- **THEN** the document header SHALL include the version string alongside the title

#### Scenario: Version falls back gracefully

- **WHEN** compiled outside a git repository (git describe fails)
- **THEN** the version SHALL display as "dev" without breaking the build

### Requirement: Buildable via just recipe

The project SHALL have a `cheatsheet` recipe in the `justfile` that:

- Calls `typst compile --pdf-standard a-2u` with the version input
- Outputs the PDF to `docs/cheatsheet/clotcad-cheatsheet.pdf`
- Does not require `mkdir -p` (file is known to exist)

#### Scenario: just recipe produces valid PDF/A

- **WHEN** `just cheatsheet` is run
- **THEN** a valid PDF/A-2u file SHALL exist at `docs/cheatsheet/clotcad-cheatsheet.pdf`
