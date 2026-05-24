# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-05-24

### Added

- Parametric DSL and DAG layer restored as `src/model/` — `defmodel`, `param`,
  `with-params`, `set-param!`, `set-params!`, `model-ref`, `model-color`,
  `model-display-name`, `model-layer`, `write-dag-models-to-step`,
  `read-step-into-dag`, `help`
- Versioned documentation homepage deployed to gh-pages (Staple + Clip template)
- API docstrings enriched with descriptions and examples
- GitHub Actions workflow to auto-generate docs on tag push and deploy

### Changed

- Renamed project from cl-occt-viewer to ClotCAD
- Renamed viewer workspace package from `CL-OCCT-USER` to `CLOTCAD-USER`
  (nicknames `CAD-USER`, `OCCT-USER`)
- Updated stale GitHub URLs to `torusJKL/ClotCAD` across README, homepage, and ASDF
- Updated cl-occt submodule to 4207763
- `def` now registers shape in DAG registry and appears grayed in Scene Tree
- `display` now registers a simple model in the DAG registry
- `show` resolves from DAG registry if not yet displayed
- `resolve-shape` moved to model layer — looks up DAG registry only
  (no viewer coupling, no broken reference to cl-occt.impl)
- Package definitions consolidated to `src/package.lisp`

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
