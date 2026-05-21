## ADDED Requirements

### Requirement: File dialogs follow application theme
The system SHALL render all QFileDialog instances in the current application color scheme (light or dark mode), using the same palette tokens as the rest of the UI.

#### Scenario: File dialog renders with dark theme
- **WHEN** the application theme is dark (e.g. `(theme-dark)` called)
- **THEN** any QFileDialog opened for STEP/STL/Lisp import-export SHALL have a dark background (`{{window-bg}}`), light text (`{{window-fg}}`), and styled subwidgets matching the dark palette

#### Scenario: File dialog renders with light theme
- **WHEN** the application theme is light (e.g. `(theme-light)` called)
- **THEN** any QFileDialog opened for STEP/STL/Lisp import-export SHALL have a light background (`{{window-bg}}`), dark text (`{{window-fg}}`), and styled subwidgets matching the light palette

#### Scenario: File dialog theme updates on theme switch
- **WHEN** the user switches themes (e.g. `(theme-dark)` then `(theme-light)`)
- **AND** a file dialog is opened after the switch
- **THEN** the dialog SHALL use the newly active theme colors

### Requirement: File dialog subwidgets are styled
The system SHALL style the following QFileDialog subwidgets to match the application theme: dialog background, filename input field, file list view, file tree view, filter combo box, action buttons (Open/Save/Cancel), column headers, and informational labels.

#### Scenario: Filename input field has themed colors
- **WHEN** a file dialog is open
- **THEN** the `QLineEdit` for the filename SHALL use `{{input-bg}}` as background and `{{input-fg}}` as text color

#### Scenario: File list has themed selection colors
- **WHEN** a file dialog is open
- **AND** the user clicks on a file in the list
- **THEN** the selected item SHALL use `{{selection-bg}}` as background and `{{selection-fg}}` as text color

#### Scenario: Action buttons match button theme
- **WHEN** a file dialog is open
- **THEN** the Open/Save and Cancel buttons SHALL use the same styling as `QMessageBox QPushButton` (same `{{button-bg}}`, `{{button-fg}}`, `{{button-border}}`, hover, and pressed states)
