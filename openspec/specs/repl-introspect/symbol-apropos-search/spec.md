## ADDED Requirements

### Requirement: Search packages for symbols matching a substring

The system SHALL provide a `(browse pattern &key :packages :case-insensitive)` macro that searches for symbols whose names contain a given substring.

`browse` SHALL accept a bare symbol (e.g. `(browse box)`), a string (e.g. `(browse "box")`), or a quoted symbol (e.g. `(browse 'box)`).  Bare symbols are auto-quoted by the macro.
By default, `browse` SHALL search only the `:clotcad` and `:cl-occt` packages (the user's primary API surface).
When `:packages t` is passed, `browse` SHALL search all packages.
When `:packages` is a list of package names, `browse` SHALL search only those packages.

#### Scenario: browse with substring match finds matching symbols

- **WHEN** the user evaluates `(browse "make")`
- **THEN** the output SHALL include symbols like `make-box`, `make-cylinder`, `make-sphere`, `make-cone`, `make-torus`, `make-prism`, `make-revol`

#### Scenario: browse with :packages t searches all packages

- **WHEN** the user evaluates `(browse "defmodel" :packages t)`
- **THEN** the output SHALL include `defmodel` from the `:clotcad` package regardless of default scope

#### Scenario: browse with a specific package list

- **WHEN** the user evaluates `(browse "map" :packages '(:cl))`
- **THEN** the output SHALL include `mapcar`, `mapc`, `map` etc. from `COMMON-LISP`

#### Scenario: browse with a symbol pattern behaves same as string

- **WHEN** the user evaluates `(browse 'make-box)`
- **THEN** the output SHALL be identical to `(browse "make-box")`

#### Scenario: browse with no matches prints a message

- **WHEN** the user evaluates `(browse "xyznonexistent")`
- **THEN** the output SHALL be `"No matches found for \"xyznonexistent\""`

### Requirement: browse output is grouped by package

The `browse` macro (via `browse-impl`) SHALL group results by package name and indicate the type of each symbol (function, macro, variable, etc.).

#### Scenario: browse output groups by package

- **WHEN** the user evaluates `(browse "make")`
- **THEN** the output SHALL be structured as:
  ```
  CLOTCAD:
    make-box (function)
    make-cylinder (function)
    make-compound (function)
    ...
  CL-OCTT:
    make-prism (function)
    make-revol (function)
    ...
  ```

#### Scenario: browse returns nil after printing

- **WHEN** the user evaluates `(values (browse "make"))`
- **THEN** the only value returned SHALL be `nil`

### Requirement: browse uses case-insensitive matching by default

The `browse` macro (via `browse-impl`) SHALL use case-insensitive substring matching by default, controlled by `:case-insensitive` keyword (default `t`).

#### Scenario: browse case-insensitive matching

- **WHEN** the user evaluates `(browse "MAKE")`
- **THEN** the output SHALL include the same matches as `(browse "make")`

#### Scenario: browse case-sensitive matching

- **WHEN** the user evaluates `(browse "make" :case-insensitive nil)`
- **THEN** the output SHALL only match symbols with exactly `make` in lowercase
