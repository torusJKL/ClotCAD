## ADDED Requirements

### Requirement: Multi-line input field

The REPL input SHALL be a multi-line text area supporting newlines, cursor placement on any line, and scrollable content.

#### Scenario: Newlines are preserved

- **WHEN** user pastes or types multi-line text (e.g., `(def :b1\n  (make-box 10 10 10))`)
- **THEN** the input field contains the exact text with newlines preserved
- **THEN** pressing Enter evaluates the expression normally

#### Scenario: Cursor navigation within input

- **WHEN** user enters a multi-line expression
- **THEN** cursor can be moved to any line using Up/Down arrow keys within the text
- **THEN** cursor can be moved to any position using mouse click

#### Scenario: Enter submits, Shift+Enter inserts newline (default)

- **WHEN** user presses Enter in the input field
- **THEN** the expression is submitted for evaluation
- **WHEN** user presses Shift+Enter
- **THEN** a newline is inserted into the input text

#### Scenario: History recall shows full multi-line text

- **WHEN** user submits a multi-line expression
- **THEN** pressing Ctrl+Up recalls the full multi-line text
- **THEN** the input field shows the expression exactly as originally typed with all newlines

#### Scenario: Scrollable input for long expressions

- **WHEN** user enters an expression longer than the visible area
- **THEN** a vertical scrollbar appears in the input area

#### Scenario: Resizable input area

- **WHEN** user drags the divider between output and input areas
- **THEN** the input area resizes vertically to show more (or fewer) lines
- **WHEN** user types or pastes text taller than the input area
- **THEN** the input area scrolls (same as Scenario: Scrollable input)
