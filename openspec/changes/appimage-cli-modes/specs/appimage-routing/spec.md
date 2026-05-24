## ADDED Requirements

### Requirement: Mode dispatch from AppRun
The AppImage `AppRun` entry point SHALL dispatch to different modes based on the first CLI argument.

#### Scenario: Default mode (viewer)
- **WHEN** the AppImage is executed with no arguments
- **THEN** ClotCAD starts in viewer mode with Slynk on 4005 and Alive LSP on 4006

#### Scenario: --viewer mode
- **WHEN** the AppImage is executed with `--viewer`
- **THEN** ClotCAD starts in viewer mode (Slynk on 4005, Alive LSP on 4006)

#### Scenario: --slynk mode
- **WHEN** the AppImage is executed with `--slynk`
- **THEN** ClotCAD starts in headless Slynk-only mode

#### Scenario: --alive mode
- **WHEN** the AppImage is executed with `--alive`
- **THEN** ClotCAD starts in headless Alive LSP-only mode

### Requirement: Port flag passthrough
The AppRun SHALL parse `-p`/`--port` and `-a`/`--alive-port` flags for the headless and viewer modes and forward them correctly.

#### Scenario: --viewer with custom ports
- **WHEN** the AppImage is executed with `--viewer -p 4007 -a 4008`
- **THEN** Slynk starts on 4007 and Alive LSP starts on 4008

#### Scenario: --slynk with custom port
- **WHEN** the AppImage is executed with `--slynk -p 4007`
- **THEN** Slynk starts on 4007

#### Scenario: --alive with custom port
- **WHEN** the AppImage is executed with `--alive -a 4008`
- **THEN** Alive LSP starts on 4008

### Requirement: Backward compatibility
The AppRun SHALL preserve backward compatibility — double-click launching and bare `./ClotCAD.AppImage` SHALL start the full viewer as before.

#### Scenario: Double-click launches viewer
- **WHEN** the AppImage is launched via desktop environment (no arguments)
- **THEN** the full viewer starts with default ports
