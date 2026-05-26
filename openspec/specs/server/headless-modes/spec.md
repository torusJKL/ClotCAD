## ADDED Requirements

### Requirement: Headless Slynk mode
The system SHALL provide a mode that starts only the Slynk server (no Qt viewer, no Alive LSP) and keeps the process alive.

#### Scenario: Start headless Slynk
- **WHEN** the AppImage is started with `--slynk`
- **THEN** ClotCAD starts Slynk on port 4005 and the process stays alive, accepting SLY connections

#### Scenario: Custom Slynk port
- **WHEN** the AppImage is started with `--slynk -p 4007`
- **THEN** ClotCAD starts Slynk on port 4007 instead of 4005

#### Scenario: Graceful shutdown
- **WHEN** the headless Slynk process receives SIGINT (Ctrl+C)
- **THEN** the process exits cleanly without entering the debugger

#### Scenario: No display required
- **WHEN** the AppImage is started with `--slynk` on a system without `$DISPLAY` and `QT_QPA_PLATFORM=offscreen` is set
- **THEN** ClotCAD starts successfully without a Qt viewer

### Requirement: Headless Alive LSP mode
The system SHALL provide a mode that starts only the Alive LSP server (no Qt viewer, no Slynk) and keeps the process alive.

#### Scenario: Start headless Alive LSP
- **WHEN** the AppImage is started with `--alive`
- **THEN** ClotCAD starts Alive LSP on port 4006 and the process stays alive, accepting LSP connections

#### Scenario: Custom Alive LSP port
- **WHEN** the AppImage is started with `--alive -a 4008`
- **THEN** ClotCAD starts Alive LSP on port 4008 instead of 4006
