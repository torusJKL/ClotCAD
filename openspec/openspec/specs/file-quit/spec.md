## ADDED Requirements

### Requirement: File menu contains Quit command

The File menu SHALL contain a "Quit" command that closes the application.

#### Scenario: Quit via menu

- **WHEN** user selects File > Quit from the menu
- **THEN** the viewer window SHALL close and the application SHALL terminate

#### Scenario: Quit via keyboard shortcut

- **WHEN** user presses Ctrl+Q
- **THEN** the viewer window SHALL close and the application SHALL terminate

### Requirement: Quit action has standard placement and label

The Quit action SHALL appear at the bottom of the File menu, separated from the export actions by a menu separator, with the label "&Quit" (platform-accelerated Q).

#### Scenario: Menu item placement

- **WHEN** the File menu is opened
- **THEN** a "Quit" action SHALL be visible after a separator at the bottom of the menu

#### Scenario: Keyboard shortcut visible

- **WHEN** the File menu is opened
- **THEN** the Quit action SHALL display "Ctrl+Q" as its shortcut hint
