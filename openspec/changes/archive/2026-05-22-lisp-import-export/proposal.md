## Why

Users need to load Lisp source files (configuration, parametric models) into the viewer and save REPL sessions for reuse or debugging. Currently only STEP/STL data import/export is supported — there is no way to import executable Lisp code (with full model definitions, parameters, and operations) or export a session log.

## What Changes

- **Import Lisp files**: New File menu action "Import Lisp..." that reads a `.lisp` file and evaluates each form sequentially on the Qt main thread (same as typing it in the REPL), with yielding between forms so the UI stays interactive.
- **Cancellable import**: Users can cancel an in-progress import via a REPL function, a status bar clickable label, or a keyboard shortcut, with cancellation checked between form evaluations.
- **Configurable replay speed**: A `replay-speed` function controls the delay between forms during import (nil = immediate, integer = milliseconds).
- **Security warning**: Importing Lisp files shows a prominent danger dialog before proceeding, and every form + its result is echoed to the REPL output in real-time.
- **Export REPL history**: New File menu action "Export REPL History..." that writes the REPL session log to a `.lisp` file. A `result-export` toggle controls whether REPL outputs are included as comments (debug mode) or omitted (clean mode).

## Capabilities

### New Capabilities

- `lisp-file-import`: Import a `.lisp` file with sequential form evaluation on the Qt main thread, tick-based yielding between forms, cancellation (Ctrl+G, status bar, REPL function), configurable speed, danger warning dialog, and real-time echo to the REPL.
- `repl-history-export`: Capture all REPL input/output in a Lisp-side log, write the log to a `.lisp` file, toggleable debug mode via `result-export` (includes results as comments).

### Modified Capabilities

None — this is a purely additive change.

## Impact

- **C++** (`wrap/`): New menu items in `ViewerWindow`; new `viewer_post_event_delayed` C API function; danger warning dialog; Ctrl+G shortcut; status bar interaction for import progress/cancel.
- **Lisp** (`src/viewer/`): Import state machine vars and tick processing in `queue.lisp` / new `import.lisp`; `*repl-log*` capture in `repl.lisp`; new user-facing functions (`replay-speed`, `cancel-import`, `result-export`, `export-repl-history`); extended `handle-file-op` dispatch.
- **Bindings** (`src/viewer/bindings.lisp`): New CFFI binding for `viewer_post_event_delayed`.
- **Tests** (`t/`): New test cases for import tick, cancellation, log capture, export formatting. Mock additions for the new CFFI function.
- **No new dependencies** — all additions use existing infrastructure (queue, WakeEvent, file-op callback, REPL output).
