## ADDED Requirements

### Requirement: AppImage

The build pipeline SHALL produce a single `.AppImage` file that contains all runtime dependencies and runs on any Linux distribution with glibc 2.39 or later.

#### Scenario: AppImage is executable
- **WHEN** user runs `./ClotCAD-*.AppImage`
- **THEN** the application window opens within 5 seconds

#### Scenario: AppImage does not require FUSE
- **WHEN** user passes `--appimage-extract-and-run`
- **THEN** the application runs identically

#### Scenario: AppImage contains SBCL
- **WHEN** user runs `./ClotCAD-*.AppImage --appimage-extract`
- **THEN** the extracted directory contains `sbcl/bin/sbcl`

#### Scenario: AppImage contains OCCT libraries
- **WHEN** the AppImage is extracted
- **THEN** `lib/occt/` contains `libTKernel.so*`, `libTKOpenGl.so*`, `libTKV3d.so*`, and all other OCCT libs needed at runtime

#### Scenario: AppImage contains Qt6 libraries
- **WHEN** the AppImage is extracted
- **THEN** `lib/qt6/` contains `libQt6Core.so.6`, `libQt6Gui.so.6`, `libQt6Widgets.so.6`, `libQt6OpenGL.so.6`, `libQt6OpenGLWidgets.so.6`, and `plugins/platforms/libqxcb.so`

### Requirement: Tarball

The build pipeline SHALL produce a `.tar.gz` archive with identical content layout to the AppImage AppDir.

#### Scenario: Tarball extracts to correct layout
- **WHEN** user runs `tar xzf ClotCAD-*.tar.gz`
- **THEN** the extracted directory contains `ClotCAD.core`, `run.sh`, `lib/`, `share/`, `sbcl/`

#### Scenario: Tarball runs on system with Qt6
- **WHEN** user runs `./run.sh` from the extracted directory on a system with Qt6 installed
- **THEN** the application window opens

### Requirement: SBCL core dump

The build pipeline SHALL generate a SBCL heap image (`ClotCAD.core`) via `save-lisp-and-die` that has `:cl-occt-viewer` and `:swank` pre-loaded.

#### Scenario: Core loads without ASDF overhead
- **WHEN** SBCL starts with `--core ClotCAD.core --eval t`
- **THEN** the process exits without loading any ASDF systems or contacting Quicklisp

#### Scenario: Core contains viewer system
- **WHEN** SBCL starts with `--core ClotCAD.core --eval '(find-symbol "BOOTSTRAP" :cl-occt-viewer)'`
- **THEN** it returns a non-nil symbol

### Requirement: Bootstrap function

The system SHALL provide a `cl-occt-viewer:bootstrap` function that starts a Swank server in a background thread on port 4005, then calls `start-viewer`.

#### Scenario: Swank starts on port 4005
- **WHEN** `bootstrap` is called
- **THEN** a Swank server is listening on TCP port 4005 within 2 seconds

#### Scenario: Viewer window opens
- **WHEN** `bootstrap` is called
- **THEN** the viewer window opens and the Qt event loop runs

### Requirement: License bundle

The distribution SHALL include a `share/licenses/` directory with all required open-source license texts and a README mapping each component to its license.

#### Scenario: All licenses are present
- **WHEN** the distribution is extracted
- **THEN** `share/licenses/` contains `GPL-3.0.txt`, `LGPL-2.1.txt`, `LGPL-3.0.txt`, and `README.md`

#### Scenario: License README maps components
- **WHEN** `share/licenses/README.md` is read
- **THEN** it MUST map "ClotCAD" to "GPL-3.0.txt", "Open CASCADE Technology" to "LGPL-2.1.txt", and "Qt6" to "LGPL-3.0.txt"

### Requirement: Launcher script

The distribution SHALL include a `run.sh` (AppRun for AppImage) that sets `LD_LIBRARY_PATH` to include bundled Qt6, OCCT, and ClotCAD libraries, then executes SBCL with the core dump.

#### Scenario: Launcher discovers bundled Qt6
- **WHEN** `lib/qt6/` exists in the distribution
- **THEN** the launcher SHALL add `lib/qt6` and `lib/qt6/plugins` to `LD_LIBRARY_PATH`

### Requirement: CI pipeline

The CI pipeline SHALL build both the AppImage and tarball on Ubuntu 24.04, bundling SBCL 2.6.0, and upload both as release artifacts.

#### Scenario: CI produces both artifacts
- **WHEN** the CI workflow runs on a tag push
- **THEN** both `ClotCAD-*.AppImage` and `ClotCAD-*.tar.gz` are produced

#### Scenario: CI uses bundled SBCL 2.6.0
- **WHEN** the CI workflow runs
- **THEN** the `sbcl/bin/sbcl` in the distribution reports version 2.6.0
