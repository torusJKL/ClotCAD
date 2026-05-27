## ADDED Requirements

### Requirement: Viewer starts maximized by default
The system SHALL start the viewer window in maximized state when no explicit `--width`/`--height` command-line flags are provided.

#### Scenario: Default launch without size flags
- **WHEN** the user runs `run.sh --viewer` (or just `run.sh`) without `--width` or `--height`
- **THEN** the viewer window SHALL be shown in maximized state

#### Scenario: Launch with explicit width/height
- **WHEN** the user runs `run.sh --width 1280 --height 720`
- **THEN** the viewer window SHALL open at exactly 1280×720 pixels, non-maximized

#### Scenario: Headless mode ignores size flags
- **WHEN** the user runs `run.sh --slynk` or `run.sh --alive` with any combination of `--width`/`--height`
- **THEN** a usage error SHALL be displayed and the program SHALL exit

#### Scenario: Lisp API backward compatibility
- **WHEN** Lisp code calls `(clotcad:start-viewer)` with no keyword arguments
- **THEN** the window SHALL start maximized

#### Scenario: Lisp API explicit size
- **WHEN** Lisp code calls `(clotcad:start-viewer :width 800 :height 600)`
- **THEN** the window SHALL open at 800×600, non-maximized
