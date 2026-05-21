## ADDED Requirements

### Requirement: Runtime key binding configuration

The REPL SHALL provide a Lisp API to change the modifier keys for history navigation and expression submission at runtime.

#### Scenario: Configure Ctrl+Enter to submit

- **WHEN** user calls `(set-repl-submit-key :ctrl)`
- **THEN** pressing Ctrl+Enter submits the expression
- **THEN** pressing plain Enter inserts a newline

#### Scenario: Configure plain Up/Down for history

- **WHEN** user calls `(set-repl-history-key :none)`
- **THEN** pressing plain Up/Down navigates history (no modifier needed)
- **THEN** Ctrl+Up/Down no longer has an effect on history

#### Scenario: Configure Alt modifier for history

- **WHEN** user calls `(set-repl-history-key :alt)`
- **THEN** pressing Alt+Up navigates backward through history
- **THEN** pressing Alt+Down navigates forward through history

#### Scenario: Default key bindings on startup

- **WHEN** viewer starts
- **THEN** the default key bindings SHALL be: Enter to submit, Ctrl+Up/Ctrl+Down for history navigation

#### Scenario: Configuration is per-viewer-instance

- **WHEN** multiple viewer instances exist (if supported)
- **THEN** key binding configuration applies only to the specified viewer instance

### Requirement: Lisp API for key configuration

The system SHALL export `set-repl-history-key` and `set-repl-submit-key` from the `cl-occt-viewer` package.

#### Scenario: set-repl-history-key accepts :ctrl, :none, :alt

- **WHEN** user calls `(set-repl-history-key :ctrl)`
- **THEN** no error is signaled
- **WHEN** user calls `(set-repl-history-key :unknown)`
- **THEN** an error is signaled

#### Scenario: set-repl-submit-key accepts :none, :ctrl, :alt

- **WHEN** user calls `(set-repl-submit-key :none)`
- **THEN** no error is signaled
- **WHEN** user calls `(set-repl-submit-key :shift)` (invalid)
- **THEN** an error is signaled
