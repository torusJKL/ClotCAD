## ADDED Requirements

### Requirement: Print docstring for any named symbol

The system SHALL provide a `(doc name)` macro that prints the documentation string and arglist for a function, macro, variable, type, or CLOS class, without requiring the caller to specify a type argument.

`doc` SHALL accept a bare symbol (e.g. `make-box`), a string (e.g. `"make-box"`), or a function object (e.g. `#'make-box`).  Bare symbols are auto-quoted by the macro.
`doc` SHALL attempt documentation types in order: `function`, `variable`, `type`, `structure`, `class`, and print all found.

#### Scenario: doc on a function shows name, package, arglist, and docstring

- **WHEN** the user evaluates `(doc make-box)`
- **THEN** the output SHALL include the fully-qualified name (`CLOTCAD/make-box`), the arglist (`dx dy dz`), and the function's docstring

#### Scenario: doc on a variable shows name, package, and docstring

- **WHEN** the user evaluates `(doc *params*)`
- **THEN** the output SHALL include the fully-qualified name (`CLOTCAD/*params*`) and the variable's docstring

#### Scenario: doc on a macro shows arglist and docstring

- **WHEN** the user evaluates `(doc defmodel)`
- **THEN** the output SHALL include the arglist and the macro's docstring

#### Scenario: doc on a symbol with no documentation prints a clear message

- **WHEN** the user evaluates `(doc 'non-existent-symbol)`
- **THEN** the output SHALL be `"No documentation found for NON-EXISTENT-SYMBOL"`

#### Scenario: doc on a function object works the same as on its symbol

- **WHEN** the user evaluates `(doc #'make-box)`
- **THEN** the output SHALL be identical to `(doc make-box)`

#### Scenario: doc on a string resolves the symbol

- **WHEN** the user evaluates `(doc "make-box")`
- **THEN** the output SHALL be identical to `(doc make-box)`

#### Scenario: doc on a CLOS class prints the class docstring

- **WHEN** the user evaluates `(doc 'shape)` (the cl-occt class)
- **THEN** the output SHALL include the class documentation if available

#### Scenario: doc prints the arglist via sb-kernel:%fun-lambda-list

- **WHEN** the user evaluates `(doc make-box)`
- **THEN** the output SHALL include `dx dy dz` as the arglist, extracted via `sb-kernel:%fun-lambda-list` for the function

#### Scenario: doc gracefully handles CFFI callbacks without arglist

- **WHEN** a CFFI callback symbol is passed to `doc`
- **THEN** the docstring SHALL be shown and the arglist section SHALL be omitted (no error thrown)

### Requirement: doc output formatting

The `doc` macro (via `doc-impl`) SHALL print to `*standard-output*` and return `nil`.

#### Scenario: doc output format is structured and readable

- **WHEN** the user evaluates `(doc make-box)`
- **THEN** the output SHALL follow this format:
  ```
  CLOTCAD/make-box (dx dy dz)
    Create a rectangular box shape.
    ...
  ```

#### Scenario: doc returns nil after printing

- **WHEN** the user evaluates `(values (doc make-box))`
- **THEN** the only value returned SHALL be `nil`
