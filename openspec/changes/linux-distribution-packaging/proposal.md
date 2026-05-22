## Why

ClotCAD currently requires building from source (OCCT 8.0.0, Qt6, SBCL, Quicklisp) which takes ~10 minutes and demands a full development toolchain. Users who just want to run the CAD application have no turn-key option. We need distribution-ready packages that work out of the box on any modern Linux system.

## What Changes

- **AppImage** — single-file portable executable bundling all dependencies
- **Full tarball** — `.tar.gz` with identical contents, for users who prefer archives
- **SBCL core dump** — precompiled Lisp heap image for instant startup
- **Swank server** — Swank runs in a background thread for SLIME connectivity
- **License bundle** — all required open-source licenses included in `share/licenses/`
- **CI pipeline** — automated builds producing both artifacts on Ubuntu 24.04

No code behavior changes — only packaging, build tooling, and distribution mechanics.

## Capabilities

### New Capabilities

- `distribution-packaging`: Build and packaging pipeline for AppImage and tarball releases. Covers the dist/ directory assembly, SBCL core dump generation, dependency bundling (OCCT, Qt6, SBCL), license inclusion, and CI automation.

### Modified Capabilities

None.

## Impact

- **New files**: `scripts/make-core.lisp`, `scripts/package.sh`, `share/licenses/*`, `share/ClotCAD.desktop`, `src/viewer/lifecycle.lisp` (bootstrap function addition)
- **Modified files**: `justfile` (new recipes), `.gitignore` (new artifact patterns)
- **Dependencies**: `linuxdeploy` + `linuxdeploy-plugin-qt` + `appimagetool` on CI (not runtime deps)
- **Build machine**: Ubuntu 24.04, glibc 2.39, Qt6 from apt, SBCL 2.6.0 bundled
