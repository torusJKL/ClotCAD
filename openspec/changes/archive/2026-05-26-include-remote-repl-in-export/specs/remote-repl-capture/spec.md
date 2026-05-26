## ADDED Requirements

### Requirement: Capture Slynk evaluations

The system SHALL record every evaluation performed through Slynk (port 4005) in `*repl-log*`, including both the submitted code and the resulting output.

#### Scenario: Slynk eval is logged
- **WHEN** a user evaluates Lisp code via SLY through the Slynk connection on port 4005
- **THEN** the code and its output SHALL appear in `*repl-log*`
- **AND** the entry SHALL be included in the next `export-repl-history` call

#### Scenario: Slynk eval with multiple forms is logged as one entry
- **WHEN** a user evaluates multiple top-level forms via SLY
- **THEN** the submitted code block and concatenated output SHALL appear as a single entry in `*repl-log*`

### Requirement: Capture Alive LSP evaluations

The system SHALL record every evaluation performed through the Alive LSP server (port 4006) in `*repl-log*`, including both the submitted code and the resulting output.

#### Scenario: Alive LSP eval is logged
- **WHEN** a user evaluates Lisp code via an LSP client through port 4006
- **THEN** the code and its output SHALL appear in `*repl-log*`
- **AND** the entry SHALL be included in the next `export-repl-history` call

#### Scenario: Alive LSP eval output includes stdout
- **WHEN** a user evaluates code that prints to stdout via Alive LSP
- **THEN** the captured stdout SHALL be included in the output portion of the `*repl-log*` entry

### Requirement: Logged entries match existing format

Remote evaluation entries in `*repl-log*` MUST use the same `(code . output)` cons-cell format as UI REPL and import entries. The output string MUST be the concatenation of all printed output and the return value(s) of the evaluated form(s).

#### Scenario: Entry format compatibility
- **WHEN** a remote evaluation is logged
- **THEN** its entry SHALL be a cons cell `(code-string . output-string)`
- **AND** `export-repl-history` SHALL process it identically to a UI REPL entry

### Requirement: Export behavior unchanged

The `export-repl-history` function SHALL export all `*repl-log*` entries, including those originating from remote sources, without requiring any configuration changes or API calls.

#### Scenario: Remote entries appear in export
- **WHEN** `export-repl-history` is called after remote evaluations have occurred
- **THEN** the remote evaluation entries SHALL be included in the output file
- **AND** entries SHALL appear in chronological order (newest first, consistent with current behavior)

#### Scenario: Result-export toggle applies uniformly
- **WHEN** `*export-with-output*` is `nil` and `export-repl-history` is called
- **THEN** remote evaluation entries SHALL be exported as code-only (same as UI REPL entries)
- **WHEN** `*export-with-output*` is `t` and `export-repl-history` is called
- **THEN** remote evaluation entries SHALL include output as `;` comments (same as UI REPL entries)
