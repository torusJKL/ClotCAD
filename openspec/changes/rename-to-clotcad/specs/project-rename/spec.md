## RENAMED Requirements

### Requirement: ASDF system name

**FROM:** `:cl-occt-viewer`
**TO:** `:clotcad`

#### Scenario: Load renamed system via Quicklisp
- **WHEN** a user evaluates `(ql:quickload :clotcad)`
- **THEN** the system loads without errors and its components are available

#### Scenario: Old system name is invalid
- **WHEN** a user evaluates `(ql:quickload :cl-occt-viewer)`
- **THEN** ASDF signals a system-not-found error

### Requirement: ASDF test system name

**FROM:** `:cl-occt-viewer/tests`
**TO:** `:clotcad/tests`

#### Scenario: Load renamed test system
- **WHEN** a user evaluates `(asdf:load-system :clotcad/tests :force t)`
- **THEN** the test system loads without errors

### Requirement: Lisp implementation package

**FROM:** `:cl-occt-viewer.impl`
**TO:** `:clotcad.impl`

#### Scenario: Package exists
- **WHEN** a user evaluates `(find-package :clotcad.impl)`
- **THEN** a non-nil package object is returned

### Requirement: Lisp public API package

**FROM:** `:cl-occt-viewer`
**TO:** `:clotcad`

#### Scenario: Package exists and re-exports symbols
- **WHEN** a user evaluates `(find-package :clotcad)`
- **THEN** a non-nil package object is returned that `:use`s `:clotcad.impl`

### Requirement: Lisp workspace package

**FROM:** `:cl-occt-user`
**TO:** `:clotcad-user`

#### Scenario: Workspace package exists
- **WHEN** a user evaluates `(find-package :clotcad-user)`
- **THEN** a non-nil package object is returned with nickname `:cad-user`

### Requirement: Shared library filename

**FROM:** `libocctviewer.so`
**TO:** `libclotcad.so`

#### Scenario: Shared library loads via CFFI
- **WHEN** the system starts and loads the foreign library
- **THEN** `libclotcad.so` is loaded without errors
