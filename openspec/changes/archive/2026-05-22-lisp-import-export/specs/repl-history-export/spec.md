## ADDED Requirements

### Requirement: REPL log capture
The system SHALL maintain a Lisp-side list `*repl-log*` that captures every REPL interaction. Each entry SHALL be a `(code . output)` pair where `code` is the full input string submitted to the REPL (after accumulator resolution) and `output` is the concatenated result string. The log SHALL capture both manually typed REPL input and forms evaluated during Lisp file import.

#### Scenario: REPL input captured in log
- **WHEN** the user types `(+ 1 2)` in the REPL and presses Enter
- **THEN** `*repl-log*` SHALL contain an entry with code `"(+ 1 2)"` and output `"3\n"`

#### Scenario: Multi-form input captured as single entry
- **WHEN** the user types `(+ 1 2) (* 3 4)` in the REPL
- **THEN** `*repl-log*` SHALL contain a single entry with the combined output

#### Scenario: Import forms captured in log
- **WHEN** a Lisp file with forms is imported
- **THEN** each evaluated form SHALL produce an entry in `*repl-log*`

### Requirement: Export REPL history to file
The system SHALL provide a File → "Export REPL History..." menu action that opens a save file dialog. When a path is selected, the system SHALL write the contents of `*repl-log*` to that file. The file dialog SHALL use `QFileDialog::DontUseNativeDialog` and filter for `Lisp Files (*.lisp *.LISP)`.

#### Scenario: Export menu item exists
- **WHEN** the user opens the File menu
- **THEN** they SHALL see "Export REPL History..." listed and clickable

#### Scenario: Save dialog opens with correct filter
- **WHEN** the user clicks "Export REPL History..."
- **THEN** a QFileDialog in save mode SHALL open with title "Export REPL History" and filter "Lisp Files (*.lisp *.LISP)"

### Requirement: Clean export mode
By default (or when `*export-with-output*` is `nil`), the system SHALL write only the user's input code to the file, one form per entry. The file SHALL be a valid Lisp source file (each line is a complete form).

#### Scenario: Clean export writes code only
- **WHEN** the REPL log contains `(def :s (make-sphere 5))` with output `"NIL\n"` and `*export-with-output*` is `nil`
- **THEN** the exported file SHALL contain `(def :s (make-sphere 5))\n` without the output

### Requirement: Debug export mode
When `*export-with-output*` is `t`, the system SHALL include REPL output as Lisp comments after each input form. Each output line SHALL be prefixed with `; `.

#### Scenario: Debug export writes code with commented output
- **WHEN** the REPL log contains `(def :s (make-sphere 5))` with output `"NIL\n"` and `*export-with-output*` is `t`
- **THEN** the exported file SHALL contain `(def :s (make-sphere 5))\n; NIL\n`

### Requirement: Toggle export mode via REPL function
The system SHALL provide a `result-export` function that accepts `t` or `nil`. Setting it to `t` enables debug mode (output included). Setting it to `nil` enables clean mode (code only). The default SHALL be `nil` (clean mode).

#### Scenario: result-export t enables debug
- **WHEN** the user types `(result-export t)`
- **THEN** subsequent exports SHALL include REPL output as comments

#### Scenario: result-export nil enables clean
- **WHEN** the user types `(result-export nil)`
- **THEN** subsequent exports SHALL include code only

### Requirement: Export uses existing file-op callback
The export SHALL use the existing `file_op_callback` mechanism with op code 5. The Lisp `handle-file-op` callback SHALL handle op=5 by calling the export function.

#### Scenario: Export dispatched through file-op callback
- **WHEN** the user exports REPL history via the menu
- **THEN** the C++ side SHALL call `file_op_callback(path, 5)` and the Lisp side SHALL handle op code 5
