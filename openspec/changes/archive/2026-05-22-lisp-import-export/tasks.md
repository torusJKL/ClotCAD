## 1. C++: Delayed event posting

- [x] 1.1 Add `viewer_post_event_delayed` declaration to `wrap/occt_viewer.h`
- [x] 1.2 Implement `viewer_post_event_delayed` in `wrap/occt_viewer.cpp` using `QTimer::singleShot` to post a WakeEvent after the given delay

## 2. C++: Menu items and wiring

- [x] 2.1 Add `myImportLispAction` and `myExportReplHistoryAction` to `wrap/viewer_window.h` with accessor methods
- [x] 2.2 Add "Import Lisp..." and "Export REPL History..." entries to the File menu in `wrap/viewer_window.cpp`
- [x] 2.3 Wire "Import Lisp..." menu action in `wrap/occt_viewer.cpp` to open a QFileDialog (title "Import Lisp", filter "Lisp Files (*.lisp *.LISP)", ExistingFile mode, DontUseNativeDialog) and call `file_op_callback(path, 4)` on accept, with danger dialog before proceeding
- [x] 2.4 Wire "Export REPL History..." menu action in `wrap/occt_viewer.cpp` to open a QFileDialog (title "Export REPL History", filter "Lisp Files (*.lisp *.LISP)", AnyFile mode, AcceptSave, DontUseNativeDialog) and call `file_op_callback(path, 5)` on accept

## 3. C++: Danger warning dialog

- [x] 3.1 Before calling `file_op_callback(path, 4)` for Lisp import, show a QMessageBox::Warning dialog with red-colored header text explaining the danger of executing arbitrary Lisp code, "Cancel" button (default) and "I understand the risk, import anyway" button. Only proceed if the user confirms.

## 4. C++: Cancel shortcut and status bar

- [x] 4.1 Add Ctrl+G QShortcut on ViewerWindow that calls `importCancelRequested` signal, connected to `file_op_callback("", 99)` sentinel
- [x] 4.2 Add a clickable QLabel to the status bar in `wrap/viewer_window.cpp` that is shown/hidden during import, displaying "Importing N/M..." with mouse press connected to `importCancelRequested` signal
- [x] 4.3 Expose `viewer_set_import_status(vwr, show, current, total)` C function so Lisp can update the status bar during import

## 5. Lisp: CFFI bindings

- [x] 5.1 Add `%viewer-post-event-delayed` defcfun to `src/viewer/bindings.lisp`
- [x] 5.2 Add `%viewer-set-import-status` defcfun to `src/viewer/bindings.lisp`

## 6. Lisp: Import state machine

- [x] 6.1 Add import state variables (`*import-forms*`, `*import-speed*`, `*import-cancelled*`, `*import-total*`, `*import-done*`) to `src/viewer/repl.lisp`
- [x] 6.2 Implement `process-import-tick` function: check cancellation, eval current form, echo to REPL, log to `*repl-log*`, update counter, schedule next tick (immediate or delayed based on `*import-speed*`)
- [x] 6.3 Wire `process-import-tick` into `drain-queue` in `src/viewer/queue.lisp` as a new phase at the end (no-op when no import active)
- [x] 6.4 Implement `cancel-import` function that sets `*import-cancelled*` to t
- [x] 6.5 Implement `replay-speed` function that sets `*import-speed*` (nil = immediate, integer = ms delay)
- [x] 6.6 Update `handle-file-op` callback in `src/viewer/repl.lisp` to handle op=4: read all forms from file, populate import state, start import tick loop via `%viewer-post-event`

## 7. Lisp: REPL log and export

- [x] 7.1 Add `*repl-log*` variable (list of `(code . output)` pairs) and `*export-with-output*` to `src/viewer/repl.lisp`
- [x] 7.2 Add logging logic to the `eval-string` callback: push `(full-code . output)` to `*repl-log*` before writing to C result buffer
- [x] 7.3 Add logging to `process-import-tick`: push each evaluated form + result to `*repl-log*`
- [x] 7.4 Implement `export-repl-history` function that writes `*repl-log*` to a file in clean mode (code only) or debug mode (code + commented output) based on `*export-with-output*`
- [x] 7.5 Implement `result-export` function that sets `*export-with-output*` to t or nil
- [x] 7.6 Update `handle-file-op` callback to handle op=5: call `export-repl-history` with the given path

## 8. Tests

- [x] 8.1 Add `%viewer-post-event-delayed` and `%viewer-set-import-status` to the mock list in `with-mocked-viewer` in `t/viewer-tests.lisp`
- [x] 8.2 Test import-tick processes one form per call
- [x] 8.3 Test cancellation flag stops processing mid-import
- [x] 8.4 Test error in a form does not stop the import (remaining forms still evaluated)
- [x] 8.5 Test `*repl-log*` capture via direct push
- [x] 8.6 Test `export-repl-history` clean mode (code only)
- [x] 8.7 Test `export-repl-history` debug mode (code + commented output)
- [x] 8.8 Test `replay-speed` sets `*import-speed*`
- [x] 8.9 Test `cancel-import` is no-op when no import active
- [x] 8.10 Test `result-export` toggles `*export-with-output*`

## 9. Documentation

- [x] 9.1 Update `AGENTS.md` with the new `*repl-log*`, `cancel-import`, `replay-speed`, `result-export` symbols in the mock list documentation
- [x] 9.2 Update `README.md` with instructions for using the Lisp import/export features
