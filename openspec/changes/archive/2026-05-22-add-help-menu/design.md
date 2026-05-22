## Context

The application has a menu bar with File and View menus but no Help menu. The About dialog is a standard desktop convention. The ClotCAD logo already exists at `share/icons/ClotCAD-logo.svg` but is not referenced anywhere in code. All existing menu/dialog code lives in C++ (Qt6 widgets) with no Lisp involvement for UI creation.

## Goals / Non-Goals

**Goals:**
- Add a Help menu with a single "About ClotCAD" action
- Show a dialog displaying the logo, app name, description, and clickable links to dependency projects
- Follow existing code patterns (C++ Qt6 widgets, synchronous `exec()`, no Lisp UI)

**Non-Goals:**
- No Lisp-side changes (the dialog is purely a C++ Qt concern)
- No version auto-detection from build system (statically written in the dialog)
- No additional Help menu items beyond About (no "Help Contents", "Documentation", etc.)

## Decisions

1. **Custom QDialog over QMessageBox** — QMessageBox does not support rich layouts (logo + description + multiple links with different targets). A custom QDialog with QVBoxLayout/QLabel gives full control.

2. **Qt Resource System (.qrc) for the logo** — Embedding `ClotCAD-logo.svg` via a `.qrc` file (compiled by `qt6_add_resources` in CMake) ensures the logo is always available regardless of working directory or install path.

3. **Clickable links via QLabel with rich text** — QLabel's `setOpenExternalLinks(true)` combined with `<a href="...">` markup is the simplest cross-platform approach, requiring zero external dependencies.

4. **Dialog implemented as a static method** — A free function `showAboutDialog(QWidget* parent)` avoids creating a new class file. The dialog is small enough that a dedicated `.h/.cpp` pair would be over-engineering.

5. **`DontUseNativeDialog` not needed** — Unlike QFileDialog (which crashes with native dialogs on some configs), QDialog has no native rendering on Linux and works reliably by default.

6. **Synced `exec()` model** — Same as existing file dialogs: block the event loop until the user closes the dialog. No need for async patterns here.

## Risks / Trade-offs

- **Hardcoded version string** → The version text will need manual updates. Acceptable for now — no build system versioning exists.
- **Link URLs in source** → If URLs change, a rebuild is required. Acceptable — dependencies don't change URLs frequently.
- **Logo file in .qrc** → Adds a new resource file and CMake integration. Simple, one-time addition.
