## Why

The in-window REPL is the primary interaction point for modeling in the viewer, but two usability gaps slow down the workflow: (a) only the first S-expression is evaluated when multiple forms are entered (e.g., `(def :b1 (make-box 10 10 10)) (def :s1 (make-sphere 10))` silently drops `:s1`), and (b) the input is a single-line `QLineEdit` that strips newlines on paste, making multi-line editing impossible and forcing users to type complex expressions all on one line.

## What Changes

- **Multi-form evaluation**: The `eval-string` callback in `repl.lisp` will loop to read and evaluate all complete S-expressions in the input buffer, not just the first one.
- **Multi-line input**: Replace the `QLineEdit` input widget with a `QPlainTextEdit`, enabling multi-line editing, paste preservation, and arbitrary cursor placement.
- **Key bindings**: Enter submits the expression; Shift+Enter inserts a newline. History navigation via Ctrl+Up / Ctrl+Down.
- **Runtime-configurable key bindings**: Lisp-side setters (`set-repl-history-key`, `set-repl-submit-key`) to change the modifier keys for history and submit actions without recompiling C++.
- **Updated documentation**: README updated to document the new REPL features and key bindings.

## Capabilities

### New Capabilities
- `multi-form-eval`: REPL evaluates all complete S-expressions in a single input, not just the first one.
- `multi-line-input`: REPL input is a multi-line text area supporting newline preservation, cursor placement on any line, and scrollable content.
- `repl-key-config`: Lisp runtime API to configure the modifier keys for history navigation and expression submission.

### Modified Capabilities
<!-- No existing specs to modify -->

## Impact

- **C++ source**: `wrap/repl_panel.h` (replace `QLineEdit` with `QPlainTextEdit`, add config fields and setters), `wrap/repl_panel.cpp` (rewrite `keyPressEvent`, `onInputSubmitted`, add new methods), `wrap/occt_viewer.h` (add `viewer_set_repl_history_modifier`, `viewer_set_repl_submit_modifier`), `wrap/occt_viewer.cpp` (implement new C API functions)
- **Lisp source**: `src/viewer/repl.lisp` (loop eval in `eval-string`, add `set-repl-history-key`, `set-repl-submit-key`), `src/viewer/bindings.lisp` (add CFFI bindings for new C functions), `src/viewer/package.lisp` (export new symbols)
- **Tests**: `t/viewer-tests.lisp` (add tests for multi-form eval, update mock list for new CFFI functions)
- **Docs**: `README.md` (document new REPL capabilities and key binding configuration)
