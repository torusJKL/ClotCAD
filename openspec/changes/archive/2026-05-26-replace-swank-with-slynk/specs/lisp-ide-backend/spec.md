## ADDED Requirements

### Requirement: Slynk server starts on port 4005
The system SHALL start a Slynk server listening on TCP port 4005 when `bootstrap` is called (distribution) or when `start.lisp` is loaded (development).

#### Scenario: Bootstrap starts Slynk server
- **WHEN** `bootstrap` is called
- **THEN** a Slynk server SHALL be started on port 4005

#### Scenario: Development script starts Slynk server
- **WHEN** `start.lisp` is loaded
- **THEN** a Slynk server SHALL be started on port 4005

### Requirement: Slynk runs in a dedicated thread
The Slynk server SHALL run in its own SBCL thread, separate from the main/UI thread.

#### Scenario: Thread created for Slynk
- **WHEN** `bootstrap` or `start.lisp` starts Slynk
- **THEN** a new SBCL thread named `"slynk"` SHALL be created

#### Scenario: Thread keeps running
- **WHEN** the Slynk thread is created
- **THEN** it SHALL loop with `(sleep 1)` to stay alive after starting the server

### Requirement: Default package is cl-occt-user
All evaluations from the IDE (SLY) SHALL default to the `cl-occt-user` package.

#### Scenario: Package binding set
- **WHEN** the Slynk thread is initialized
- **THEN** `slynk:*default-worker-thread-bindings*` SHALL bind `*package*` to the `cl-occt-user` package
- **THEN** the user can type `(make-sphere 20)` instead of `(cl-occt-user:make-sphere 20)`

### Requirement: Graceful fallback when Slynk unavailable
The system SHALL NOT crash if Slynk is not available. It SHALL warn and continue without the IDE backend.

#### Scenario: Slynk not loaded
- **WHEN** `bootstrap` is called but Slynk is not available
- **THEN** a warning SHALL be printed
- **THEN** the viewer SHALL start without a Slynk server

#### Scenario: Slynk not loaded (development)
- **WHEN** `start.lisp` is loaded but Slynk is not available
- **THEN** the script SHALL print a warning
- **THEN** the viewer SHALL start without a Slynk server

### Requirement: Slynk is quickloaded at core build time
The `make-core.lisp` script SHALL quickload `:slynk` so it is available in the distribution core dump without network access.

#### Scenario: Core dump loads Slynk
- **WHEN** `make-core.lisp` is executed
- **THEN** `(ql:quickload :slynk :silent t)` SHALL be called

### Requirement: SLY connectivity
The Slynk server SHALL be compatible with the SLY editor. SLIME (which uses the Swank protocol) is NOT supported.

#### Scenario: SLY connects
- **WHEN** SLY connects to port 4005
- **THEN** the REPL SHALL be functional
- **THEN** evaluations SHALL default to the `cl-occt-user` package

### Requirement: README documents Slynk usage
The README.md SHALL document that the project uses Slynk on port 4005 for IDE connectivity.

#### Scenario: README mentions Slynk
- **WHEN** a user reads README.md
- **THEN** they SHALL see a reference to Slynk on port 4005
