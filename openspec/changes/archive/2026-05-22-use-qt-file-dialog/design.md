## Context

The viewer application uses `QFileDialog` in `wrap/occt_viewer.cpp` for four file operations: import STEP, import STL, export STEP, export STL. Each dialog is configured with `setFileMode` and `setAcceptMode` and launched modally via `exec()`. By default, Qt6 delegates to the system-native file dialog, which crashes on some configurations. The fix is straightforward: opt out of the native dialog via `DontUseNativeDialog`.

## Goals / Non-Goals

**Goals:**
- Eliminate crashes when opening file import/export dialogs
- Preserve all existing dialog behavior (file filter, accept/reject, path returned)
- Keep the change minimal — touch only the dialog configuration

**Non-Goals:**
- No API changes — `QFileDialog` public API is unchanged
- No UI redesign — layout, labels, and filters remain identical
- No Lisp-side changes — `repl.lisp` already handles the returned path correctly

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| How to suppress native dialog | `QFileDialog::DontUseNativeDialog` option | Single-flag approach. Minimal diff, no new classes or abstraction layers. |
| Which dialogs to apply to | All four (import STEP/STL, export STEP/STL) | Consistency. If one crashes, the others are equally at risk. |
| Dialog-option style | `.setOption(QFileDialog::DontUseNativeDialog)` after construction, before `exec()` | Follows Qt best practices. Can be placed right after the existing `setAcceptMode` calls. |

## Risks / Trade-offs

| Risk | Mitigation |
|------|------------|
| Qt-style dialogs may look slightly different from OS-native ones | This is the intended behavior. The trade-off between appearance and stability is acceptable. |
| `DontUseNativeDialog` might be unavailable on very old Qt6 versions | Qt6.0+ supports it. Project already requires Qt6. |
| Future Qt versions might deprecate `DontUseNativeDialog` | If deprecated, switch to a helper wrapper factory function — but this is speculative and low risk. |
