# slyc-debugger-escape Specification

## Purpose
TBD - created by archiving change handle-sbcl-debugger. Update Purpose after archive.
## Requirements
### Requirement: SIGUSR1 handler aborts all stuck threads

The system SHALL install a signal handler for `SIGUSR1` in `bootstrap`. When SIGUSR1 is received, the handler SHALL iterate all SBCL threads, find any that are currently in the debugger, and abort them by invoking `sb-debug:abort` on each.

#### Scenario: SIGUSR1 handler installed at startup

- **WHEN** `bootstrap` is called
- **THEN** `sb-sys:enable-interrupt` SHALL be called for `SIGUSR1` with a handler function

#### Scenario: SIGUSR1 aborts stuck Qt thread

- **WHEN** the Qt main thread has entered the SBCL debugger due to an unhandled condition
- **WHEN** the user sends `SIGUSR1` to the ClotCAD process (e.g., `kill -USR1 <pid>`)
- **THEN** the handler SHALL detect the Qt main thread is in the debugger
- **THEN** the handler SHALL invoke `sb-debug:abort` on that thread
- **THEN** the Qt event loop SHALL resume
- **THEN** the REPL SHALL show a message about the aborted debugger

#### Scenario: SIGUSR1 with no stuck threads is harmless

- **WHEN** no thread is currently in the debugger
- **WHEN** the user sends `SIGUSR1`
- **THEN** the handler SHALL do nothing and return

### Requirement: Slyc-compatible escape script

The system SHALL provide a Lisp form that can be evaluated via `slyc --eval` to trigger the SIGUSR1 escape mechanism by sending SIGUSR1 to the current process.

#### Scenario: slyc escape form sends SIGUSR1

- **WHEN** the user runs `slyc --eval '(sb-unix:unix-kill (sb-unix:unix-getpid) sb-unix:sigusr1)'` while ClotCAD is frozen
- **THEN** the Slynk server SHALL receive the eval request
- **THEN** the eval SHALL send SIGUSR1 to the ClotCAD process
- **THEN** the SIGUSR1 handler SHALL abort any stuck thread
- **THEN** the viewer SHALL unfreeze

#### Scenario: Escape form in script file provided

- **WHEN** the user runs `slyc --eval "$(cat scripts/slyc-debugger-escape.lisp)"`
- **THEN** the behavior SHALL be identical to the inline form above

