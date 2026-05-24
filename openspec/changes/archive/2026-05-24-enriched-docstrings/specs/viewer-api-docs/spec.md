## ADDED Requirements

### Requirement: Viewer functions have enriched docstrings
All public functions exported from the `:clotcad` viewer package (files under `src/viewer/`) SHALL have docstrings that follow the `cl-occt` convention with bold section markers, backtick-quoted code references, and bullet-list parameter documentation.

The convention SHALL use:
- `**Returns:**` for return value documentation
- `**Example:**` for executable usage examples
- `**See also:**` for cross-references to related functions
- `- **param** description` for parameter documentation
- Backtick-quoted names for inline code references (e.g., `` `shape` ``)
- `;; =>` annotations to show return values in examples

#### Scenario: Existing docstrings are converted to bold convention
- **WHEN** a viewer function currently uses `Example:` (no bold)
- **THEN** it SHALL be updated to `**Example:**`
- **AND** `See also:` SHALL be updated to `**See also:**`
- **AND** inline return descriptions SHALL be extracted into `**Returns:**` sections

#### Scenario: Existing docstrings gain missing examples
- **WHEN** a viewer function has a docstring with no `**Example:**` section
- **AND** it is not a trivial predicate (e.g., `shape-p`)
- **THEN** a `**Example:**` section SHALL be added with executable code

#### Scenario: Missing docstrings are added
- **WHEN** a public viewer function has no docstring (`display`, `clear-all`, `log-remote-eval`)
- **THEN** a full docstring SHALL be added following the cl-occt convention with parameters, returns, example, and see-also sections as applicable

#### Scenario: Trivial predicates skip examples
- **WHEN** a function is a simple type predicate (returns `t` or `nil` with no side effects)
- **THEN** the docstring SHALL omit the `**Example:**` section

### Requirement: Viewer functions use consistent parameter documentation
All viewer functions with parameters SHALL document them using `- **name** description` bullet lists.

#### Scenario: Parameters are documented as bullets
- **WHEN** a function has explicit parameters
- **THEN** each parameter SHALL be documented as `- **name** description` on its own line
- **AND** the description SHALL explain the parameter's purpose, type, and valid values

### Requirement: Viewer docstring examples are runnable
All `**Example:**` sections SHALL contain runnable Common Lisp code that a user could evaluate at the REPL.

#### Scenario: Example code evaluates correctly
- **WHEN** an example contains code
- **THEN** it SHALL be valid Common Lisp syntax
- **AND** it SHALL reference only exported symbols from `:clotcad` or standard packages
