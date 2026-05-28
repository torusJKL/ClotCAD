## ADDED Requirements

### Requirement: REPL `,abort` command interrupts stuck thread

The `eval-string` callback SHALL recognize REPL input starting with `,` as a special command. The command `,abort` SHALL find the thread currently in the debugger and abort it.

#### Scenario: ,abort invokes sb-debug:abort on stuck thread

- **WHEN** the user types `,abort` in the Qt REPL
- **THEN** the system SHALL find any thread where the debugger is active
- **THEN** the system SHALL interrupt that thread with `sb-thread:interrupt-thread` calling `sb-debug:abort`
- **THEN** the REPL SHALL print a confirmation message like `"Aborted debugger on thread <name>"`

#### Scenario: ,abort with no stuck thread prints message

- **WHEN** the user types `,abort` in the Qt REPL and no thread is currently in the debugger
- **THEN** the REPL SHALL print a message like `"No thread is currently in the debugger"`

#### Scenario: ,abort works via Slynk eval thread, not Qt thread

- **WHEN** the user types `,abort` in the Qt REPL and the Slynk eval thread is in the debugger (not the Qt thread)
- **THEN** the Qt REPL SHALL successfully evaluate the abort command and interrupt the Slynk thread

### Requirement: REPL `,restart <name>` command invokes named restart

The `eval-string` callback SHALL support `,restart <name>` to invoke a named restart on the thread in the debugger.

#### Scenario: ,restart invokes named restart

- **WHEN** the user types `,restart abort` in the Qt REPL
- **THEN** the system SHALL find the thread in the debugger
- **THEN** the system SHALL find the restart named `ABORT` on the condition
- **THEN** the system SHALL invoke the restart
- **THEN** confirmation SHALL be printed to the REPL

#### Scenario: ,restart with unknown name prints error

- **WHEN** the user types `,restart nonexistent-restart` in the Qt REPL
- **THEN** the REPL SHALL print `"No restart named NONEXISTENT-RESTART found"`

### Requirement: `,debug` command shows debugger status

The REPL SHALL support `,debug` to display which threads are in the debugger and what restarts are available.

#### Scenario: ,debug shows stuck threads

- **WHEN** the user types `,debug` in the Qt REPL
- **THEN** the REPL SHALL list any threads currently in the debugger
- **THEN** for each stuck thread, the REPL SHALL show available restarts
- **THEN** if no threads are stuck, the REPL SHALL print `"No threads in debugger"`

### Requirement: `,errors` command shows recent caught errors

The REPL SHALL support `,errors` and `,errors <N>` to display the last N error entries from `*repl-log*` that were logged by the debugger hook.

#### Scenario: ,errors shows last 5 errors by default

- **WHEN** the user types `,errors` in the Qt REPL and there are 10 errors in `*repl-log*`
- **THEN** the REPL SHALL display the 5 most recent errors
- **THEN** each entry SHALL show the condition type, message, thread, and available restarts

#### Scenario: ,errors with count shows N errors

- **WHEN** the user types `,errors 3` in the Qt REPL
- **THEN** the REPL SHALL display the 3 most recent errors

#### Scenario: ,errors with no errors prints message

- **WHEN** the user types `,errors` in the Qt REPL and no errors have been caught
- **THEN** the REPL SHALL print `"No errors recorded"`

### Requirement: `,help` command lists available commands

The REPL SHALL support `,help` to list all available debugger commands.

#### Scenario: ,help shows available commands

- **WHEN** the user types `,help` in the Qt REPL
- **THEN** the REPL SHALL list all available comma-commands

### Requirement: `*debugger-invocation-count*` tracks hook firings

The system SHALL provide `*debugger-invocation-count*`, a counter exported from `:clotcad` that increments each time the global debugger hook catches a condition.

#### Scenario: counter increments on hook call

- **WHEN** the global debugger hook is called
- **THEN** `*debugger-invocation-count*` SHALL be incremented by 1
