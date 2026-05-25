## ADDED Requirements

### Requirement: System provides default init path
The system SHALL check for `~/.config/clotcad/init.lisp` at startup. If the file exists and no `--init` argument was provided, the system SHALL load and evaluate its contents.

#### Scenario: Default init file exists
- **WHEN** ClotCAD starts in any mode with `~/.config/clotcad/init.lisp` present and no `--init` flag
- **THEN** the system evaluates each Lisp form in the file in order
- **AND** in UI mode, evaluation progress is shown in the REPL panel

#### Scenario: Default init file does not exist
- **WHEN** ClotCAD starts with no `~/.config/clotcad/init.lisp` and no `--init` flag
- **THEN** no init file is loaded
- **AND** startup proceeds normally with no warning

### Requirement: CLI --init argument overrides default path
The `--init FILE` CLI argument SHALL specify an alternative init file. When provided, SHALL skip the default `~/.config/clotcad/init.lisp` path. The argument SHALL accept an absolute or relative file path.

#### Scenario: --init with custom path
- **WHEN** ClotCAD starts with `--init /home/user/my-init.lisp`
- **THEN** the system evaluates `/home/user/my-init.lisp` form-by-form
- **AND** does NOT check `~/.config/clotcad/init.lisp`

#### Scenario: --init with relative path
- **WHEN** ClotCAD starts with `--init my-init.lisp`
- **THEN** the path SHALL be resolved relative to the current working directory

#### Scenario: --init file does not exist
- **WHEN** ClotCAD starts with `--init /nonexistent/path.lisp`
- **THEN** the system SHALL emit a warning on stderr
- **AND** startup proceeds normally

### Requirement: Init file loads form-by-form in UI mode
In `--viewer` mode, the init file SHALL be evaluated one form at a time through the same `process-import-tick` pipeline used by File > Import Lisp. Each form SHALL be displayed in the REPL output panel along with its return value or error message.

#### Scenario: Multi-form init file in UI mode
- **WHEN** the init file contains multiple Lisp forms
- **THEN** forms are evaluated one at a time in order
- **AND** each form and its result appear in the REPL output
- **AND** the import progress indicator updates

#### Scenario: Error in one form does not stop others
- **WHEN** an init file form signals an error
- **THEN** the error is displayed in the REPL output
- **AND** subsequent forms continue evaluation

### Requirement: Init file loads synchronously in headless mode
In `--slynk` or `--alive` mode, the init file SHALL be evaluated synchronously before the server starts accepting connections.

#### Scenario: Headless mode with init file
- **WHEN** ClotCAD starts with `--slynk --init config.lisp`
- **THEN** all forms in `config.lisp` are evaluated before the Slynk server enters its accept loop
- **AND** evaluation errors are printed to stderr but do not prevent the server from starting

### Requirement: Error handling
The system SHALL NOT abort startup due to an error in the init file. In UI mode, errors are shown in the REPL. In headless mode, errors are printed to stderr. The viewer or server SHALL continue starting after the init file completes.

#### Scenario: Syntax error in init file
- **WHEN** the init file contains a read error
- **THEN** the error is caught by `handler-case`
- **AND** in headless mode, an error message is printed to stderr
- **AND** the system continues startup

### Requirement: --no-init flag skips all init files
The `--no-init` CLI flag SHALL prevent any init file from being loaded. This overrides both the default config path and any `--init` argument.

#### Scenario: --no-init with default config file present
- **WHEN** ClotCAD starts with `--no-init` and `~/.config/clotcad/init.lisp` exists
- **THEN** no init file is loaded
- **AND** startup proceeds normally with no warning

#### Scenario: --no-init with --init
- **WHEN** ClotCAD starts with `--no-init --init /custom/path.lisp`
- **THEN** no init file is loaded
- **AND** the system emits no warning

### Requirement: No init file is the default
The init file is entirely optional. ClotCAD SHALL function identically to current behavior when no init file exists and no `--init` is specified.

#### Scenario: Fresh install, no init file
- **WHEN** ClotCAD starts on a fresh system with no `~/.config/clotcad/` directory
- **THEN** no init file is loaded
- **AND** no warning or error is emitted
- **AND** the viewer starts normally
