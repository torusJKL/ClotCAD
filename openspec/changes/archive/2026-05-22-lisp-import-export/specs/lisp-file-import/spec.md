## ADDED Requirements

### Requirement: Import Lisp file from menu
The system SHALL provide a File → "Import Lisp..." menu action that opens a file dialog for selecting a `.lisp` file. The file dialog SHALL use `QFileDialog::DontUseNativeDialog` (matching existing import dialogs) and filter for `Lisp Files (*.lisp *.LISP)`.

#### Scenario: Menu item exists
- **WHEN** the user opens the File menu
- **THEN** they SHALL see "Import Lisp..." listed and clickable

#### Scenario: File dialog opens with correct filter
- **WHEN** the user clicks "Import Lisp..."
- **THEN** a QFileDialog SHALL open with title "Import Lisp" and filter "Lisp Files (*.lisp *.LISP)"

### Requirement: Danger warning before import
Before any code from the imported file is evaluated, the system SHALL display a prominent warning dialog. The dialog SHALL have a warning icon, red-colored header text explaining the danger of executing arbitrary Lisp code, and two buttons: "Cancel" (default, focused) and "I understand the risk, import anyway". If Cancel is pressed, the import SHALL be aborted.

#### Scenario: Warning shown before import
- **WHEN** the user selects a `.lisp` file and presses Open
- **THEN** a danger warning dialog SHALL be displayed before any Lisp code is read or evaluated

#### Scenario: Cancel aborts import
- **WHEN** the danger warning is displayed and the user presses "Cancel"
- **THEN** no Lisp code from the file SHALL be read or evaluated

#### Scenario: Confirmation proceeds with import
- **WHEN** the danger warning is displayed and the user presses "I understand the risk, import anyway"
- **THEN** the import SHALL proceed

### Requirement: Sequential form evaluation
The system SHALL read all top-level forms from the imported `.lisp` file and evaluate them one at a time, in order, on the Qt main thread. Each form SHALL be evaluated with `eval` in the current package, the same way REPL input is evaluated. If a form signals an error, the error SHALL be caught and reported, and the next form SHALL still be evaluated (matching REPL error behavior).

#### Scenario: Forms evaluated in order
- **WHEN** a file contains `(+ 1 2)` followed by `(* 3 4)`
- **THEN** `(+ 1 2)` SHALL be evaluated first, returning 3, and `(* 3 4)` SHALL be evaluated second, returning 12

#### Scenario: Error in one form does not stop subsequent forms
- **WHEN** a file contains `(+ 1 2)`, then `(error "oops")`, then `(* 3 4)`
- **THEN** `(+ 1 2)` SHALL produce 3, the error SHALL be reported, and `(* 3 4)` SHALL still produce 12

### Requirement: REPL echo during import
The system SHALL echo every form being evaluated and its result to the REPL output panel in real-time. Each form SHALL be displayed with a `> ` prefix (matching REPL display convention), followed by its result on the next line. Results SHALL be displayed as they complete, not batched.

#### Scenario: Form echoed before result
- **WHEN** a form `(+ 1 2)` is evaluated during import
- **THEN** the REPL SHALL display `> (+ 1 2)` followed by `3`

### Requirement: UI responsiveness between forms
Between evaluations of individual forms, the system SHALL yield control to the Qt event loop, allowing the user to navigate the 3D view (pan, zoom, rotate), observe shapes appearing as they are `display`'d, and interact with the REPL or scene tree. This SHALL apply even when `replay-speed` is nil (no artificial delay).

#### Scenario: Scene updates between forms
- **WHEN** an import evaluates `(display :a (make-sphere 5))` followed by `(display :b (make-box 10 10 10))`
- **THEN** after the first form, the sphere SHALL be visible in the 3D view before the box is created

### Requirement: Cancellation via REPL function
The system SHALL provide a `cancel-import` function accessible from the REPL. When called during an active import, it SHALL set a flag that is checked before each form evaluation. Once the flag is set, the current form (if any) SHALL complete, and no further forms SHALL be evaluated.

#### Scenario: Cancel-import stops execution
- **WHEN** an import of a file with 10 forms is in progress and the user types `(cancel-import)` in the REPL
- **THEN** the current form SHALL complete, the remaining forms SHALL NOT be evaluated, and the import state SHALL be cleaned up

#### Scenario: Cancel-import when no import is active
- **WHEN** the user types `(cancel-import)` and no import is running
- **THEN** the function SHALL be a no-op (no error)

### Requirement: Cancellation via keyboard shortcut
The system SHALL provide a keyboard shortcut Ctrl+G that cancels the current import (identical effect to `cancel-import`). The shortcut SHALL be active only when an import is in progress (or SHALL be a no-op otherwise).

#### Scenario: Ctrl+G cancels import
- **WHEN** an import is in progress and the user presses Ctrl+G
- **THEN** the import SHALL be cancelled (same behavior as `cancel-import`)

### Requirement: Cancellation via status bar
When an import is in progress, the system SHALL display a clickable label in the status bar showing "Importing N/M..." where N is the current form index and M is the total number of forms. Clicking the label SHALL cancel the import (identical effect to `cancel-import`). When no import is active, the label SHALL NOT be visible.

#### Scenario: Status bar shows progress during import
- **WHEN** an import of a file with 10 forms is processing the 3rd form
- **THEN** the status bar SHALL show "Importing 3/10..." as a clickable label

#### Scenario: Clicking status label cancels import
- **WHEN** the import progress label is displayed and the user clicks it
- **THEN** the import SHALL be cancelled

#### Scenario: Status label disappears after import
- **WHEN** an import completes or is cancelled
- **THEN** the "Importing..." label SHALL be removed from the status bar

### Requirement: Configurable replay speed
The system SHALL provide a `replay-speed` function that accepts an integer (milliseconds) or `nil`. When set to an integer, the system SHALL wait that many milliseconds between each form evaluation during import. When set to `nil`, no artificial delay SHALL be added (forms process as fast as possible, still yielding to the event loop). The function SHALL affect any subsequent form evaluations during an active import (not just new imports).

#### Scenario: Replay speed delays between forms
- **WHEN** `(replay-speed 100)` is set and an import of 5 forms is started
- **THEN** at least 100 ms SHALL elapse between the end of one form's evaluation and the start of the next

#### Scenario: Nil speed means no delay
- **WHEN** `(replay-speed nil)` is set and an import is started
- **THEN** forms SHALL be evaluated back-to-back (subject only to Qt event loop scheduling)

#### Scenario: Speed change takes effect immediately
- **WHEN** an import with 20 forms is running and the user sets `(replay-speed 5000)` mid-import at form 8
- **THEN** the delay between form 8 and form 9 SHALL be 5000 ms (previous forms may have had a different speed)

### Requirement: Import uses existing file-op callback
The import SHALL use the existing `file_op_callback` mechanism with a new op code (4). The Lisp `handle-file-op` callback SHALL handle op=4 by initiating the import tick loop. This keeps the menu wiring pattern consistent with STEP/STL imports.

#### Scenario: Import dispatched through file-op callback
- **WHEN** the user imports a Lisp file via the menu
- **THEN** the C++ side SHALL call `file_op_callback(path, 4)` and the Lisp side SHALL handle op code 4

### Requirement: All forms read before evaluation starts
The system SHALL read all top-level forms from the file into memory before evaluating any of them. This ensures the total count is known for the status bar display and that file I/O errors are caught before any code runs.

#### Scenario: File read before any eval
- **WHEN** a `.lisp` file is imported
- **THEN** all forms from the file SHALL be read into memory before the first form is evaluated

#### Scenario: File read error stops import
- **WHEN** the selected file cannot be read (e.g., permissions error, binary file)
- **THEN** an error SHALL be reported and no forms SHALL be evaluated
