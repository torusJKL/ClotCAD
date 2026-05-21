## 1. Add QFileDialog QSS rules to theme template

- [x] 1.1 Open `src/viewer/theme.lisp` and locate the `*qss-template*` string (around line 232, after the QMessageBox rules)
- [x] 1.2 Add `QFileDialog` background/foreground rule using `{{window-bg}}` and `{{window-fg}}` tokens
- [x] 1.3 Add `QFileDialog QLineEdit` rule for filename input (`{{input-bg}}`, `{{input-fg}}`, border, padding)
- [x] 1.4 Add `QFileDialog QListView` and `QFileDialog QTreeView` rules for file listing area (background, text, selection colors, outline)
- [x] 1.5 Add `QFileDialog QComboBox` rule for filter dropdown (background, text, border)
- [x] 1.6 Add `QFileDialog QPushButton` rule for action buttons (reuse same tokens as `QMessageBox QPushButton` — `{{button-bg}}`, `{{button-fg}}`, `{{button-border}}`, hover, pressed)
- [x] 1.7 Add `QFileDialog QHeaderView` rule for column headers in detail view
- [x] 1.8 Add `QFileDialog QLabel` rule for informational text
- [x] 1.9 Add `QFileDialog QToolBar` and `QFileDialog QToolButton` rules so the parent-directory arrow icon uses `{{window-fg}}` color and buttons have visible hover/pressed states
- [x] 1.10 Add C++ `viewer_set_icon_palette()` function and CFFI binding that sets `QPalette::WindowText`, `ButtonText`, and `Text` from the theme foreground color — needed because QSS `color` property doesn't propagate to QToolButton standard icon generation; called from `apply-theme` with `{{window-fg}}`

## 2. Verify the implementation

- [x] 2.1 Rebuild the project (`just viewer` then `just start`)
- [x] 2.2 Test dark theme: call `(theme-dark)` in REPL, open each file dialog (Import STEP, Import STL, Export STEP, Export STL, Import Lisp, Export REPL History) and verify dark styling
- [x] 2.3 Test light theme: call `(theme-light)` in REPL, open each file dialog and verify light styling
- [x] 2.4 Test theme switch: alternate between dark and light, open dialogs after each switch to confirm they reflect the new theme
- [x] 2.5 Run `just test` to confirm no Lisp test regressions — all 116 tests pass
