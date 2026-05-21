## Why

The QFileDialog instances used for STEP/STL import-export and Lisp import/REPL export are always rendered with a dark background regardless of the current application theme (light/dark). This happens because the QSS template (`src/viewer/theme.lisp`) only has styling rules for QMessageBox but not for QFileDialog. The QMessageBox (Danger dialog) correctly follows the theme because it has explicit QSS rules — the file dialogs need the same treatment.

## What Changes

- Add `QFileDialog` styling rules to the QSS template in `src/viewer/theme.lisp` covering:
  - Background and foreground colors
  - QLineEdit (filename input)
  - QListView/QTreeView (file listing area)
  - QPushButton (Open/Save/Cancel buttons)
  - QComboBox (filter dropdown)
  - QLabel, QHeaderView, and other internal widgets
- No C++ changes needed — the dialogs are already non-native (`DontUseNativeDialog`) and inherit the application-level stylesheet

## Capabilities

### New Capabilities
- `file-dialog-theme`: File dialogs track the application theme (light/dark) consistently, with properly styled backgrounds, text, buttons, list views, and input fields

### Modified Capabilities

*(None — this is a presentation-level fix, no requirement changes.)*

## Impact

- **File**: `src/viewer/theme.lisp` — add ~30 lines of QFileDialog QSS rules to `*qss-template*`
- **No new dependencies**
- **No API changes**: existing file dialogs continue to work identically, just with correct theming
