## ADDED Requirements

### Requirement: quit-clotcad function exists and is exported

The system SHALL provide a function `quit-clotcad` in the `:clotcad` package that gracefully stops all services and exits the Lisp process. The function SHALL be exported from both `:clotcad.impl` and `:clotcad` packages.

#### Scenario: quit-clotcad is defined

- **WHEN** the `:clotcad` system is loaded
- **THEN** `fboundp 'quit-clotcad` SHALL return T

#### Scenario: quit-clotcad is accessible from clotcad-user

- **WHEN** the `:clotcad` system is loaded
- **THEN** `find-symbol "QUIT-CLOTCAD" :clotcad-user` SHALL return the function symbol

### Requirement: quit-clotcad stops all services

The function SHALL stop the Slynk server (if running), stop the Alive LSP server (if running), and stop the viewer (if running) before exiting the process.

#### Scenario: stops viewer when running in GUI mode

- **WHEN** `quit-clotcad` is called while `*viewer*` is non-nil
- **THEN** `%viewer-quit` SHALL be called on the viewer pointer
- **THEN** `%viewer-destroy` SHALL be called on the viewer pointer
- **THEN** `*viewer*` SHALL be set to nil
- **THEN** `*viewer-running*` SHALL be set to nil

#### Scenario: stops Slynk server when running

- **WHEN** `quit-clotcad` is called and Slynk is loaded
- **THEN** `slynk:stop-all-servers` SHALL be called (or equivalent stop mechanism)

#### Scenario: stops Alive LSP server when running

- **WHEN** `quit-clotcad` is called and Alive LSP is loaded
- **THEN** `alive/server:stop` SHALL be called (or equivalent stop mechanism)

#### Scenario: graceful degradation when service libraries not loaded

- **WHEN** `quit-clotcad` is called and Slynk or Alive LSP are not loaded
- **THEN** the function SHALL NOT signal an error for the missing library

### Requirement: quit-clotcad resets Lisp state

The function SHALL reset global Lisp state before exiting to avoid leaking stale references.

#### Scenario: resets REPL and model state

- **WHEN** `quit-clotcad` is called
- **THEN** `*repl-log*` SHALL be set to nil
- **THEN** `*displayed-models*` SHALL be cleared
- **THEN** `*repl-accumulator*` SHALL be reset to `""`
- **THEN** `*import-forms*` SHALL be set to nil

### Requirement: quit-clotcad exits the Lisp process

The function SHALL call `sb-ext:quit` as the final step to terminate the process cleanly.

#### Scenario: process exits with zero status

- **WHEN** `quit-clotcad` completes all teardown steps
- **THEN** `sb-ext:quit` SHALL be called with exit code 0
