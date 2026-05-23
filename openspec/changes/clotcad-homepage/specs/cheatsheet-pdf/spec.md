## ADDED Requirements

### Requirement: Cheatsheet compilation
The CI workflow SHALL compile the Typst cheatsheet source into a PDF.

#### Scenario: CI compiles cheatsheet
- **WHEN** a tag is pushed
- **THEN** `typst compile docs/cheatsheet/cheatsheet.typ` SHALL produce `cheatsheet.pdf`
- **THEN** the PDF SHALL be included in the published documentation output

### Requirement: Cheatsheet linking
The homepage navigation SHALL include a link to the cheatsheet PDF.

#### Scenario: Navigation link
- **WHEN** a user views any page on the documentation site
- **THEN** the navigation bar SHALL contain a link to `cheatsheet.pdf`

### Requirement: Source rename
The cheatsheet source file SHALL be renamed from `docs/cheatsheet/main.typ` to `docs/cheatsheet/cheatsheet.typ`.

#### Scenario: Canonical filename
- **WHEN** the project is checked out
- **THEN** the file `docs/cheatsheet/cheatsheet.typ` SHALL exist
- **THEN** the file `docs/cheatsheet/main.typ` SHALL NOT exist
