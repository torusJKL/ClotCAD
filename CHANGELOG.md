# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-05-23

### Added

- Cheatsheet (Typst, PDF/A-2u) covering 14 sections of ClotCAD usage
- AI-friendly API reference (`docs/clotcad-api.md`) with signatures and examples
- Alive LSP server on port 4006 for LSP editor support (VS Code)
- File > Quit menu item with Ctrl+Q shortcut
- Remote REPL evaluations captured in history export
- `workflow_dispatch` for manual CI release trigger
- Quicklisp dependency resolution in release workflow
- ICU library bundling in AppImage

### Changed

- Replaced Swank with Slynk for IDE connectivity (SLIME compatibility dropped)
- Bound `*package*` to `CLOTCAD-USER` in UI REPL
- Switched to binary SBCL release instead of source code build

## [0.1.0] - 2026-05-22

### Added

- Qt6 viewer with OCCT AIS (3D rendering, camera controls, MSAA)
- REPL panel with multi-form eval, multi-line input, history, configurable key bindings
- Scene tree panel with synchronized selection across 3D view, tree, and REPL
- SLIME/Swank integration on worker thread for IDE connectivity
- GPLv3 license
- `cl-occt` as git submodule at `lib/cl-occt/`
- C-to-Lisp migration: viewer state moved to Lisp (`ui.lisp`, `render.lisp`, `queue.lisp`)
- `cl-occt-user` workspace package providing unqualified access to all modeling and viewer commands
- Fluent-inspired theme system with dark/light modes, runtime accent color and font control
- Help > About dialog with logo, description, and dependency links
- Lisp file import and REPL history export (`result-export`, `export-repl-history`)
- AIS ViewCube with Z-up coordinate system
- Distribution packaging: AppImage + tarball with SBCL core dump
- Version info displayed in About dialog and distribution artifacts
- OpenSpec workflow skills and change tracking
