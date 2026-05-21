## Context

`QFileDialog` instances for STEP/STL import-export, Lisp import, and REPL history export (6 dialogs total) use `QFileDialog::DontUseNativeDialog` and inherit the application-wide QSS set via `QApplication::setStyleSheet()`. However, QFileDialog's internal widget tree includes QListView, QTreeView, QLineEdit, QComboBox, QPushButton, QLabel, and QHeaderView — subwidgets that the current QSS template (`src/viewer/theme.lisp`) does not style explicitly. The existing stylesheet only targets `QMessageBox` and its `QPushButton` children, which is why the Danger dialog renders correctly while file dialogs default to the system/Qt theme (dark on this system).

## Goals / Non-Goals

**Goals:**
- Add QSS rules for QFileDialog and its child widgets so they follow the current light/dark theme
- Cover all 6 file dialog sites without any C++ changes
- Ensure consistent look with QMessageBox (same palette tokens: window-bg, window-fg, button-bg, etc.)

**Non-Goals:**
- Changing dialog layout, behavior, or file operation callbacks
- Adding custom QFileDialog subclassing or proxy styles
- Styling system-native file dialogs (DontUseNativeDialog is already set)

## Decisions

1. **Use descendant selectors (`QFileDialog QXxx`) rather than widget-level overrides**
   - This matches the existing `QMessageBox QPushButton` pattern in the codebase
   - Avoids leaking styles to other parts of the app that use the same widget types
   - File dialogs are the only dialogs with QListView/QTreeView for file listing

2. **Style the following subwidgets** (based on Qt6 QFileDialog internals):
   - `QFileDialog` itself — background and foreground
   - `QFileDialog QLineEdit` — filename input (background, text, border, padding)
   - `QFileDialog QListView` and `QFileDialog QTreeView` — file listing area (background, text, selection colors, alternating row colors)
   - `QFileDialog QComboBox` — filter dropdown (background, text, border)
   - `QFileDialog QPushButton` — Open/Save/Cancel (same tokens as QMessageBox buttons)
   - `QFileDialog QHeaderView` — column headers in detail view
   - `QFileDialog QLabel` — informational text labels

3. **Reuse existing palette tokens** from `*qss-template*`
   - No new tokens needed; existing `{{window-bg}}`, `{{window-fg}}`, `{{button-bg}}`, `{{input-bg}}`, `{{selection-bg}}`, `{{scrollbar-bg}}` etc. cover all required colors

## Risks / Trade-offs

- **Qt version differences**: The QFileDialog internal widget structure may differ between Qt 6.x minor versions. The QSS selectors should be general enough (descendant selectors) to work across versions.
- **`DontUseNativeDialog` required**: The styling only works with the Qt-built dialog. Native OS dialogs cannot be styled. This is already the case.
- **No test coverage for visual styling**: The Lisp test suite mocks CFFI and cannot verify QSS output. Manual visual verification is needed.
