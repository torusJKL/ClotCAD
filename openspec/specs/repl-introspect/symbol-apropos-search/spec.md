## ADDED Requirements

### Requirement: Search packages for symbols matching a substring

The system SHALL provide an `(apropos pattern &key :packages :case-insensitive)` macro that searches for symbols whose names contain a given substring.

`apropos` SHALL accept a bare symbol (e.g. `(apropos box)`), a string (e.g. `(apropos "box")`), or a quoted symbol (e.g. `(apropos 'box)`).  Bare symbols are auto-quoted by the macro.
By default, `apropos` SHALL search only the `:clotcad` and `:cl-occt` packages (the user's primary API surface).
When `:packages t` is passed, `apropos` SHALL search all packages (like CL's `apropos`).
When `:packages` is a list of package names, `apropos` SHALL search only those packages.

Note: This macro shadows `cl:apropos`.  `(:shadow :apropos)` is used in `:clotcad` defpackage, and `(:shadowing-import-from :clotcad :apropos)` is used in `:clotcad-user`.

#### Scenario: apropos with substring match finds matching symbols

- **WHEN** the user evaluates `(apropos "make")`
- **THEN** the output SHALL include symbols like `make-box`, `make-cylinder`, `make-sphere`, `make-cone`, `make-torus`, `make-prism`, `make-revol`

#### Scenario: apropos with :packages t searches all packages

- **WHEN** the user evaluates `(apropos "defmodel" :packages t)`
- **THEN** the output SHALL include `defmodel` from the `:clotcad` package regardless of default scope

#### Scenario: apropos with a specific package list

- **WHEN** the user evaluates `(apropos "map" :packages '(:cl))`
- **THEN** the output SHALL include `mapcar`, `mapc`, `map` etc. from `COMMON-LISP`

#### Scenario: apropos with a symbol pattern behaves same as string

- **WHEN** the user evaluates `(apropos 'make-box)`
- **THEN** the output SHALL be identical to `(apropos "make-box")`

#### Scenario: apropos with no matches prints a message

- **WHEN** the user evaluates `(apropos "xyznonexistent")`
- **THEN** the output SHALL be `"No matches found for \"xyznonexistent\""`

### Requirement: apropos output is grouped by package

The `apropos` macro (via `apropos-impl`) SHALL group results by package name and indicate the type of each symbol (function, macro, variable, etc.).

#### Scenario: apropos output groups by package

- **WHEN** the user evaluates `(apropos "make")`
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

#### Scenario: apropos returns nil after printing

- **WHEN** the user evaluates `(values (apropos "make"))`
- **THEN** the only value returned SHALL be `nil`

### Requirement: apropos uses case-insensitive matching by default

The `apropos` macro (via `apropos-impl`) SHALL use case-insensitive substring matching by default, controlled by `:case-insensitive` keyword (default `t`).

#### Scenario: apropos case-insensitive matching

- **WHEN** the user evaluates `(apropos "MAKE")`
- **THEN** the output SHALL include the same matches as `(apropos "make")`

#### Scenario: apropos case-sensitive matching

- **WHEN** the user evaluates `(apropos "make" :case-insensitive nil)`
- **THEN** the output SHALL only match symbols with exactly `make` in lowercase
