## ADDED Requirements

### Requirement: File dialogs use non-native Qt6 style
All import/export file dialogs in the application SHALL use Qt6's built-in (non-native) file dialog instead of the system-native dialog.

#### Scenario: Import STEP dialog uses non-native style
- **WHEN** user triggers Import STEP action
- **THEN** the file dialog SHALL open with Qt6 style (non-native), not the OS-native dialog

#### Scenario: Import STL dialog uses non-native style
- **WHEN** user triggers Import STL action
- **THEN** the file dialog SHALL open with Qt6 style (non-native), not the OS-native dialog

#### Scenario: Export STEP dialog uses non-native style
- **WHEN** user triggers Export STEP action
- **THEN** the file dialog SHALL open with Qt6 style (non-native), not the OS-native dialog

#### Scenario: Export STL dialog uses non-native style
- **WHEN** user triggers Export STL action
- **THEN** the file dialog SHALL open with Qt6 style (non-native), not the OS-native dialog

### Requirement: File dialog functionality preserved
Setting `DontUseNativeDialog` SHALL NOT alter the file selection, filter, accept, or reject behavior of any dialog.

#### Scenario: Import STEP accepts valid path
- **WHEN** user selects a `.step` file and clicks Open
- **THEN** the dialog SHALL return the selected file path as before

#### Scenario: Export STEP accepts valid path
- **WHEN** user enters a filename and clicks Save
- **THEN** the dialog SHALL return the entered path as before

#### Scenario: Dialog filter works correctly
- **WHEN** user opens any import/export dialog
- **THEN** the file filter SHALL show only the relevant file types (`.step`/`.stl`)

#### Scenario: Dialog cancel returns empty
- **WHEN** user clicks Cancel on any file dialog
- **THEN** no file operation SHALL be triggered
