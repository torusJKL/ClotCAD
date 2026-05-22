## MODIFIED Requirements

### Requirement: Slynk server starts on port 4005
The system SHALL start a Slynk server listening on TCP port 4005 AND an Alive LSP server on port 4006 when `bootstrap` is called (distribution) or when `start.lisp` is loaded (development).

#### Scenario: Bootstrap starts both servers
- **WHEN** `bootstrap` is called
- **THEN** a Slynk server SHALL be started on port 4005
- **THEN** an Alive LSP server SHALL be started on port 4006

#### Scenario: Development script starts both servers
- **WHEN** `start.lisp` is loaded
- **THEN** a Slynk server SHALL be started on port 4005
- **THEN** an Alive LSP server SHALL be started on port 4006

### Requirement: Slynk runs in a dedicated thread
The system SHALL run the Slynk server in its own SBCL thread AND the Alive LSP server in its own SBCL thread, each separate from the main/UI thread.

#### Scenario: Threads created for both servers
- **WHEN** `bootstrap` or `start.lisp` starts both servers
- **THEN** an SBCL thread named `"slynk"` SHALL be created for Slynk
- **THEN** an SBCL thread named `"alive-lsp"` SHALL be created for Alive LSP

### Requirement: Graceful fallback when IDE backend unavailable
The system SHALL NOT crash if Slynk or Alive LSP is not available. It SHALL warn and continue without the unavailable backend(s).

#### Scenario: Only Slynk unavailable
- **WHEN** `bootstrap` is called but Slynk is not available
- **THEN** a warning SHALL be printed about Slynk
- **THEN** Alive LSP SHALL still be started if available
- **THEN** the viewer SHALL start

#### Scenario: Only Alive LSP unavailable
- **WHEN** `bootstrap` is called but Alive LSP is not available
- **THEN** a warning SHALL be printed about Alive LSP
- **THEN** Slynk SHALL still be started if available
- **THEN** the viewer SHALL start
