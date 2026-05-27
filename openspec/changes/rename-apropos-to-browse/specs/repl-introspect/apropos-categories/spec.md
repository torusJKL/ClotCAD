## MODIFIED Requirements

### Requirement: Category tree display on no-argument browse

**FROM:**
When `apropos` is called with no arguments, the system SHALL display a tree of all available capability categories derived from source file introspection of `:cl-occt` and `:clotcad` exported functions.

**TO:**
When `browse` is called with no arguments, the system SHALL display a tree of all available capability categories derived from source file introspection of `:cl-occt` and `:clotcad` exported functions.

#### Scenario: No-argument browse shows category tree
- **WHEN** the user types `(browse)` in the REPL
- **THEN** the output SHALL list every category with: a human-readable display name, a count of functions in that category, and representative function names

#### Scenario: Category tree is always up to date
- **WHEN** the user calls `(browse)` after a new function is defined in a cl-occt source file
- **THEN** that function SHALL appear in its file's category without any manual registration step

#### Scenario: Category tree uses compact mode in GUI REPL
- **WHEN** the user types `(browse)` in the embedded GUI REPL (where `*standard-output*` is a string stream)
- **THEN** each category line SHALL show only the display name and function count, omitting representative function names, to fit within the 4096-byte C buffer limit

#### Scenario: Category tree uses full mode in remote REPL
- **WHEN** the user types `(browse)` via a Slynk or Alive LSP connection
- **THEN** each category line SHALL include representative function names

### Requirement: Keyword category lookup

**FROM:**
When `apropos` receives a keyword symbol as its first argument, the system SHALL attempt to look up a category matching that keyword. The lookup SHALL use partial case-insensitive matching against both the display name and the filename stem of each category.

**TO:**
When `browse` receives a keyword symbol as its first argument, the system SHALL attempt to look up a category matching that keyword. The lookup SHALL use partial case-insensitive matching against both the display name and the filename stem of each category.

#### Scenario: Exact keyword matches a category
- **WHEN** the user types `(browse :fillet)`
- **THEN** the output SHALL show all functions in the "Fillets" category, each with its full lambda list and docstring

#### Scenario: Partial keyword matches a category
- **WHEN** the user types `(browse :file)`
- **THEN** the output SHALL match categories containing "file" in their display name or stem (e.g. "File I/O")

#### Scenario: Keyword matches no category
- **WHEN** the user types `(browse :boogers)`
- **THEN** the system SHALL print "No category found" and return nil
- **AND** the system SHALL NOT fall through to substring search on function names

#### Scenario: Multiple categories match a keyword
- **WHEN** the user types `(browse :face)`
- **AND** multiple categories match (e.g. "Faces" and "Face Filling")
- **THEN** the output SHALL show all matching categories with their function counts, allowing the user to drill into a specific one

### Requirement: Keyword category filtering by package

**FROM:**
The system SHALL accept a `:packages` keyword argument that filters the category tree or category detail to specific packages.

**TO:**
The system SHALL accept a `:packages` keyword argument that filters the category tree or category detail to specific packages.

#### Scenario: :packages with single designator
- **WHEN** the user types `(browse :fillet :packages :cl-occt)`
- **THEN** the system SHALL treat `:packages :cl-occt` the same as `:packages '(:cl-occt)`

#### Scenario: :packages with list
- **WHEN** the user types `(browse :fillet :packages '(:cl-occt :clotcad))`
- **THEN** the system SHALL include functions from both packages

#### Scenario: :packages with t
- **WHEN** the user types `(browse :fillet :packages t)`
- **THEN** the system SHALL search all packages

### Requirement: Existing substring search behavior preserved

**FROM:**
When `apropos` receives a string or a bare symbol as its first argument, the system SHALL behave exactly as the current implementation — substring matching against exported symbol names.

**TO:**
When `browse` receives a string or a bare symbol as its first argument, the system SHALL behave exactly as the current implementation — substring matching against exported symbol names.

#### Scenario: String argument searches function names
- **WHEN** the user types `(browse "box")`
- **THEN** the system SHALL list all exported functions with "box" in their name, with type annotations

#### Scenario: Symbol argument searches function names
- **WHEN** the user types `(browse box)`
- **THEN** the macro quotes the symbol and the system SHALL list all exported functions with "BOX" in their name

### Requirement: Category display includes fallback naming

**FROM:**
When a source file's stem has no entry in the display-name map, the system SHALL use the filename stem itself (capitalized) as the category display name.

**TO:**
When a source file's stem has no entry in the display-name map, the system SHALL use the filename stem itself (capitalized) as the category display name.

#### Scenario: Unmapped file uses filename stem
- **WHEN** a new file `widget.lisp` is added to cl-occt without a corresponding entry in the display-name map
- **THEN** `(browse)` SHALL show a category "Widget" for functions from that file

### Requirement: Documentation updated

**FROM:**
The `docs/clotcad-api.md` file SHALL be updated to document the new `apropos` modes.

**TO:**
The `docs/clotcad-api.md` file SHALL be updated to document the `browse` function.

#### Scenario: Introspection section documents browse
- **WHEN** the user reads the documentation for `browse`
- **THEN** the documentation SHALL describe: no-argument category tree, keyword category lookup, existing substring search, and the `:packages` argument
