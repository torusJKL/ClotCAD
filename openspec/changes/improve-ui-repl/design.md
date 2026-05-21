## Context

The REPL panel consists of a `QDockWidget` (C++ `REPLPanel`) wrapping a read-only `QPlainTextEdit` for output and a single-line `QLineEdit` for input. When the user presses Enter, C++ calls a CFFI callback (`eval-string`), which runs on the Qt main thread. Currently `eval-string` calls `read-from-string` exactly once — consuming only the first expression — and silently discards the rest. The `QLineEdit` widget cannot display or edit multi-line text; pasted newlines are stripped by Qt before the callback fires.

The Lisp-side `*repl-accumulator*` mechanism handles incomplete input (missing closing paren) but does not loop for multiple complete forms. There is no way to change key bindings without editing C++.

## Goals / Non-Goals

**Goals:**
- Evaluate all complete S-expressions in a single input, not just the first one.
- Replace `QLineEdit` with `QPlainTextEdit` for true multi-line input with cursor navigation.
- Enter submits the expression; Shift+Enter inserts a newline.
- Ctrl+Up/Ctrl+Down navigates history (default).
- Provide a Lisp API (`set-repl-history-key`, `set-repl-submit-key`) to change modifier keys at runtime.
- Update README to document the new capabilities.

**Non-Goals:**
- Not adding tab completion, syntax highlighting, or incremental search.
- Not changing the output area behavior (it stays read-only `QPlainTextEdit`).
- Not changing the CFFI callback signature (`eval_fn` typedef stays the same).
- Not changing the synchronous eval model (no async eval or queue-based REPL).

## Decisions

### 1. Input widget: `QPlainTextEdit` instead of `QLineEdit`

Alternatives considered: `QTextEdit` (rich text), `QScintilla` (syntax highlighting).

`QPlainTextEdit` is the right choice: it is designed for plain-text editing, has no rich-text overhead, supports `setPlainText()`/`toPlainText()`, and works well with monospace fonts. It supports arbitrary cursor positioning (click or arrow keys), selection, and scrolling — exactly what multi-line input needs.

### 2. Enter/Shift+Enter semantics

Default: **Enter submits, Shift+Enter inserts newline**. This matches the convention of Python REPL, Julia, IRB, and the Lisp listener in SLIME. The alternative (Enter=newline, Ctrl+Enter=submit) would disrupt existing muscle memory.

Made configurable via `set-repl-submit-key` so users who prefer the alternative can switch.

### 3. Resizable input area via QSplitter

The output and input areas are separated by a `QSplitter` (vertical orientation) rather than a fixed `QVBoxLayout`. The splitter handle is a draggable divider that gives the user direct control over how many lines the input displays. A reasonable default size (~3 lines) is set on the splitter. No `setFixedHeight` is applied to the input — the splitter drives sizing.

This is the standard Qt approach for resizable panes. The alternative (a separate resize handle on the input area) would be non-standard and more work to implement.

### 4. History navigation: Ctrl+Up/Ctrl+Down

Plain Up/Down arrows move the cursor within the multi-line input (standard text editing). **Ctrl+Up navigates backward through history; Ctrl+Down navigates forward.** When a history entry is recalled, the full multi-line text replaces the entire input contents, and the cursor moves to the end.

Alternative considered (context-aware: Up at first line = history) — rejected because it conflicts with the common case of editing a multi-line input where the cursor is on the first line and the user wants to move down.

Made configurable via `set-repl-history-key`.

### 4. Lisp-side key config via two separate CFFI functions

Two separate setters (`viewer_set_repl_history_modifier`, `viewer_set_repl_submit_modifier`) rather than a single struct or bitfield. Rationale: each setter is a trivial 3-line C function + 3-line CFFI binding; they are independently mockable in tests; adding a new config knob later is simply adding another setter.

### 5. No change to `eval_fn` callback signature

The existing `eval_fn` typedef (`void (*)(const char* code, char* result, int maxlen)`) works fine. The `eval-string` callback will simply loop internally. The C++ side is unchanged for the eval pathway.

### 6. Multi-form eval: loop with `read-from-string` position tracking

Instead of wrapping input in `(progn ...)`, loop by passing the `start` parameter to `read-from-string`:

```lisp
(let ((pos 0))
  (loop (multiple-value-bind (form next-pos)
            (read-from-string full-code nil *repl-eof-sentinel* :start pos)
          (when (eq form *repl-eof-sentinel*) (return))
          (eval form)
          (setf pos next-pos))))
```

This avoids modifying the user's code (no implicit `progn`) and naturally handles any number of forms. Each form is evaluated independently so an error in one form does not prevent subsequent forms from running.

## Risks / Trade-offs

- **[Backwards compatibility for accumulator-based multiline]** The existing `*repl-accumulator*` mechanism for incomplete input must still work with the loop. If the accumulated buffer has trailing incomplete input after reading all complete forms, the remainder goes back into the accumulator. Implementation must check whether `pos` consumed all of `full-code`.
- **[Error handling in multi-form eval]** If `(+ 1 2) (error "oops") (+ 3 4)` is entered, the error should be reported but the third form should still run. The loop wraps each eval in `handler-case` and collects all results/errors.
- **[History entries may be very long]** Multi-line expressions could make history entries very large. The existing cap of 1000 entries and the plaintext display seem adequate — no truncation needed.
- **[Mocking new CFFI functions in tests]** The `with-mocked-viewer` macro needs to be updated with mocks for the two new CFFI functions. The multi-form eval itself is testable without mocking (it's pure Lisp — just call the callback logic directly).
