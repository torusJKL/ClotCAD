## 1. C++: Replace QLineEdit with QPlainTextEdit

- [x] 1.1 In `wrap/repl_panel.h`: replace `QLineEdit* myInput` with `QPlainTextEdit* myInput`; add `int myHistoryModifier` and `int mySubmitModifier` fields (initialized to `Qt::ControlModifier` and `Qt::NoModifier`); declare `setConfig(int historyMod, int submitMod)` method
- [x] 1.2 In `wrap/repl_panel.cpp` constructor: construct `QPlainTextEdit` instead of `QLineEdit`; set same monospace font; set placeholder text; connect `&QPlainTextEdit::textChanged` is not needed — use event filter or override `keyPressEvent` instead of `returnPressed` signal
- [x] 1.3 Rewrite `onInputSubmitted()`: read input via `myInput->toPlainText()` instead of `myInput->text()`; clear input via `myInput->clear()`; preserve history logic
- [x] 1.4 Rewrite `keyPressEvent()`: handle Enter (check `mySubmitModifier`) vs Shift+Enter; handle Ctrl+Up/Ctrl+Down (check `myHistoryModifier`) vs plain Up/Down for cursor movement; all other events pass through to `QDockWidget::keyPressEvent`
- [x] 1.5 Replace `QVBoxLayout` with `QSplitter` (vertical) between output and input so user can resize the input area by dragging the divider; remove `setFixedHeight` on myInput

## 2. C++: Add key config C API

- [x] 2.1 In `wrap/occt_viewer.h`: declare `viewer_set_repl_history_modifier(occt_viewer, int)` and `viewer_set_repl_submit_modifier(occt_viewer, int)`
- [x] 2.2 In `wrap/occt_viewer.cpp`: implement both functions — iterate `findChildren<REPLPanel*>()` and call the corresponding setter on each

## 3. Build C++ library

- [x] 3.1 Run `just viewer` to rebuild `lib/libocctviewer.so` and confirm compilation succeeds

## 4. Lisp: CFFI bindings for key config

- [x] 4.1 In `src/viewer/bindings.lisp`: add `%viewer-set-repl-history-modifier` and `%viewer-set-repl-submit-modifier` defcfuns
- [x] 4.2 In `src/viewer/package.lisp`: export the new `%viewer-*` symbols from `cl-occt-viewer.impl`

## 5. Lisp: Multi-form eval in eval-string

- [x] 5.1 In `src/viewer/repl.lisp`: rewrite `eval-string` callback to loop — read forms sequentially using `read-from-string` with `:start` position; evaluate each form in a `handler-case`; collect all results; if incomplete input remains after consuming all complete forms, store remainder in `*repl-accumulator*`
- [x] 5.2 Ensure `*repl-accumulator*` still works: when accumulator is non-empty, prepend before looping; if the concatenated text ends with incomplete input, store leftover back in accumulator
- [x] 5.3 Handle edge case: empty input or whitespace-only input produces no output

## 6. Lisp: Key config high-level API

- [x] 6.1 In `src/viewer/repl.lisp`: add `set-repl-history-key (modifier)` and `set-repl-submit-key (modifier)` that accept `:ctrl`, `:none`, `:alt` and call the corresponding `%viewer-set-*` with the `Qt::*Modifier` value
- [x] 6.2 In `src/viewer/package.lisp`: export `set-repl-history-key` and `set-repl-submit-key` from `cl-occt-viewer`

## 7. Update tests

- [x] 7.1 Add mocks for `%viewer-set-repl-history-modifier` and `%viewer-set-repl-submit-modifier` in the `with-mocked-viewer` macro in `t/viewer-tests.lisp` (no-op lambdas)
- [x] 7.2 Add test: `multiple-simple-forms-evaluated` — exercise the multi-form eval loop directly (call the callback logic with multiple forms, verify all results)
- [x] 7.3 Add test: `incomplete-form-still-accumulates` — verify accumulator interaction with multi-form loop
- [x] 7.4 Add test: `error-in-one-form-does-not-block-others` — verify error handling in multi-form eval
- [x] 7.5 Add test: `single-form-still-works` — verify backward compatibility
- [x] 7.6 Run `just test` and confirm all tests pass

## 8. Update documentation

- [x] 8.1 Update `README.md` REPL section to document: multi-line input, Enter vs Shift+Enter behavior, Ctrl+Up/Down history navigation, key binding configuration API
- [x] 8.2 Update `README.md` Layout diagram if needed to reflect multi-line input in the REPL panel

## 9. Verify

- [x] 9.1 Build and start the viewer (`just viewer && just start`), connect via SLIME
- [x] 9.2 Test multi-form eval: `(+ 1 2) (+ 3 4)` produces `3` and `7`
- [x] 9.3 Test multi-line input: paste multi-line expression, verify newlines preserved
- [x] 9.4 Test Enter vs Shift+Enter: Enter submits, Shift+Enter inserts newline
- [x] 9.5 Test history: submit expressions, navigate with Ctrl+Up/Ctrl+Down
- [x] 9.6 Test key config: `(set-repl-history-key :none)` then use plain Up/Down for history
- [x] 9.7 Run `just test` and confirm all tests pass
