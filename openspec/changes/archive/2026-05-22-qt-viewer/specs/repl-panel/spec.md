## ADDED Requirements

### Requirement: REPL dock widget

The viewer SHALL provide a dockable REPL panel on the right side of the window with an output area and a single-line input area.

#### Scenario: REPL panel visible by default
- **WHEN** the viewer starts
- **THEN** the REPL panel SHALL be visible as a QDockWidget on the right side
- **THEN** the REPL panel SHALL be approximately 400px wide

#### Scenario: REPL output area
- **WHEN** the REPL panel is visible
- **THEN** it SHALL contain a read-only QPlainTextEdit displaying previous output
- **THEN** the font SHALL be monospace (e.g., "Courier New", 10pt)
- **THEN** new output SHALL auto-scroll to show the latest line

#### Scenario: REPL input area
- **WHEN** the REPL panel is visible
- **THEN** it SHALL contain a QLineEdit below the output area
- **THEN** the QLineEdit SHALL have placeholder text ">  (enter Lisp expression)"

#### Scenario: Evaluate Lisp expression
- **WHEN** user types text in the input field and presses Enter
- **THEN** `> <code>\n` SHALL be appended to the output area
- **THEN** `eval_callback(code, result_buffer, maxlen)` SHALL be called
- **THEN** the result SHALL be appended to the output area
- **THEN** the input field SHALL be cleared
- **THEN** the input field SHALL retain keyboard focus

#### Scenario: REPL history navigation
- **WHEN** user presses the Up arrow in the input field
- **THEN** the input SHALL show the previous expression from history
- **WHEN** user presses the Down arrow
- **THEN** the input SHALL show the next expression from history
- **WHEN** at the end of history
- **THEN** the input SHALL be cleared

#### Scenario: REPL panel toggle
- **WHEN** user toggles the REPL panel via the View menu
- **THEN** the REPL panel SHALL show or hide

### Requirement: REPL output from external code

The viewer SHALL support appending text to the REPL output from C or Lisp code.

#### Scenario: External output
- **WHEN** `viewer_append_repl_output(vwr, "text")` is called from any thread
- **THEN** "text" SHALL be appended to the REPL output area

#### Scenario: Thread-safe output
- **WHEN** `viewer_append_repl_output()` is called from a non-Qt thread
- **THEN** the text SHALL be queued and appended on the Qt main thread (thread-safe via signals/slots)
