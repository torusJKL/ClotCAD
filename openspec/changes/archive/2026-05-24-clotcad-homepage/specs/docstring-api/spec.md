## ADDED Requirements

### Requirement: API reference from source docstrings
The documentation site SHALL include an auto-generated API reference page derived from exported symbols and their docstrings.

#### Scenario: Browse API reference
- **WHEN** a user visits `https://clotcad.com/latest/`
- **THEN** the navigation SHALL include a link to the API reference
- **THEN** the API reference SHALL list all exported symbols from the `:clotcad`, `:clotcad-user`, and `:cl-occt` packages

### Requirement: Docstring formatting
Docstrings SHALL be rendered with Markdown formatting and code cross-references.

#### Scenario: Markdown in docstring renders as HTML
- **WHEN** a docstring contains Markdown (backtick code, bold, lists)
- **THEN** the rendered HTML SHALL display the formatted output

#### Scenario: Symbol cross-references in docstrings
- **WHEN** a docstring mentions an exported symbol in backticks
- **THEN** Staple SHALL convert the symbol into a clickable link to its definition

### Requirement: Docstrings include examples
Every user-facing exported function SHALL have a docstring containing at least one example of usage.

#### Scenario: Examples in docstrings
- **WHEN** a user views a function's definition on the API reference page
- **THEN** at least one code example SHALL be visible

### Requirement: Three packages documented
The API reference SHALL cover three packages together.

#### Scenario: Package listing
- **WHEN** the documentation is generated
- **THEN** it SHALL include exported symbols from `:clotcad`, `:clotcad-user`, and `:cl-occt`
