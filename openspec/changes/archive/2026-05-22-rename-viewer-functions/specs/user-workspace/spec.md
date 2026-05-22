## ADDED Requirements

### Requirement: User workspace package
The system SHALL provide a `cl-occt-user` package that `:use`s `:cl`, `:cl-occt`, and `:cl-occt-viewer`, allowing unqualified access to all exported symbols from both libraries without symbol conflicts.

#### Scenario: Package loads without conflict
- **WHEN** the system loads `:cl-occt-user`
- **THEN** no package conflict errors occur for symbols exported by both `:cl-occt` and `:cl-occt-viewer`

#### Scenario: Unqualified access to modeling functions
- **WHEN** a user is in the `:cl-occt-user` package and types `(make-sphere 20)`
- **THEN** the call resolves to `cl-occt:make-sphere`

#### Scenario: Unqualified access to viewer functions
- **WHEN** a user is in the `:cl-occt-user` package and types `(display :s * :fit-view)`
- **THEN** the calls resolve to `cl-occt-viewer:display` and `cl-occt-viewer:fit-view`

### Requirement: Package has user-friendly nicknames
The `:cl-occt-user` package SHALL have nicknames `:cad-user` and `:occt-user`.

#### Scenario: Switch to package via nickname
- **WHEN** a user types `(in-package :cad-user)` or `(in-package :occt-user)`
- **THEN** the current package becomes `:cl-occt-user`

### Requirement: Default landing package
Starting the viewer via `start.lisp` SHALL set `*package*` to `:cl-occt-user`, making modeling and viewer functions available without prefix in both the main thread and Swank REPL.

#### Scenario: Swank session lands in workspace
- **WHEN** a user connects to the Swank server on port 4005
- **THEN** the REPL prompt shows `CL-OCCT-USER>`

### Requirement: Renamed viewer functions
The viewer convenience functions `fit-all` and `set-antialiasing` SHALL be renamed to `fit-view` and `set-view-aa` respectively, to avoid symbol conflicts with `cl-occt`.

#### Scenario: fit-view fits all shapes to viewport
- **WHEN** a user calls `(fit-view)` through the viewer's Lisp layer
- **THEN** the underlying `%viewer-fit-all` CFFI function is invoked on the current viewer

#### Scenario: set-view-aa enables antialiasing
- **WHEN** a user calls `(set-view-aa t)`
- **THEN** the underlying `%viewer-set-antialiasing` CFFI function is invoked with `enable=1`

#### Scenario: set-view-aa disables antialiasing
- **WHEN** a user calls `(set-view-aa nil)`
- **THEN** the underlying `%viewer-set-antialiasing` CFFI function is invoked with `enable=0`
