## ADDED Requirements

### Requirement: Show dialog when Slynk port is in use
When Slynk fails to start because its TCP port is already bound, the system SHALL display a Qt warning dialog with the message explaining the port is in use and the REPL server cannot start. The dialog SHALL have a single "OK" button. The viewer SHALL continue loading after the dialog is dismissed.

#### Scenario: Slynk port 4005 is already in use
- **WHEN** `bootstrap` is called and port 4005 is already bound by another process
- **THEN** the viewer window appears and a warning dialog is shown with title "Port In Use" and a message indicating Slynk could not start on port 4005
- **THEN** after dismissing the dialog, the viewer operates normally without REPL functionality
- **THEN** terminal output still includes the warning message

### Requirement: Show dialog when Alive LSP port is in use
When Alive LSP fails to start because its TCP port is already bound, the system SHALL display a Qt warning dialog with the message explaining the port is in use and the LSP server cannot start. The dialog SHALL have a single "OK" button. The viewer SHALL continue loading after the dialog is dismissed.

#### Scenario: Alive LSP port 4006 is already in use
- **WHEN** `bootstrap` is called and port 4006 is already bound by another process
- **THEN** the viewer window appears and a warning dialog is shown with title "Port In Use" and a message indicating Alive LSP could not start on port 4006
- **THEN** after dismissing the dialog, the viewer operates normally without LSP functionality
- **THEN** terminal output still includes the warning message

### Requirement: Both ports in use show a single combined dialog
When both Slynk and Alive LSP ports are in use, the system SHALL display a single dialog listing both failures. Each port error SHALL appear on its own line.

#### Scenario: Both ports 4005 and 4006 are in use
- **WHEN** `bootstrap` is called and both port 4005 and port 4006 are already bound
- **THEN** the viewer window appears and a single dialog is shown containing both port failure messages
- **THEN** after dismissing the dialog, the viewer operates normally without any REPL or LSP servers

### Requirement: No dialog shown when ports are free
When all ports are available, the system SHALL NOT show any port-related dialogs. This preserves the current startup experience.

#### Scenario: All ports are free
- **WHEN** `bootstrap` is called and both port 4005 and port 4006 are available
- **THEN** no port-related dialogs are displayed
- **THEN** both Slynk and Alive LSP start normally

### Requirement: Dialog uses themed styling
The dialog SHALL use the existing Qt stylesheet so it matches the current ClotCAD theme appearance.

#### Scenario: Dialog appearance matches theme
- **WHEN** a port conflict dialog is shown
- **THEN** the dialog inherits the current QSS stylesheet applied to the viewer

### Requirement: Non-port errors do not show dialog
When Slynk or Alive LSP fail for reasons other than port-in-use (e.g., missing symbols, library errors), the system SHALL NOT show a dialog. Terminal warnings SHALL still be printed.

#### Scenario: Slynk fails for non-port reason
- **WHEN** `start-slynk` encounters an error that is not a socket address-in-use error
- **THEN** no dialog is shown
- **THEN** a warning is printed to the terminal
