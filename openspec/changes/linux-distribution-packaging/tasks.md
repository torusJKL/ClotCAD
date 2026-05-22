## 1. Bootstrap Function

- [x] 1.1 Add `bootstrap` function to `lifecycle.lisp` that starts Slynk in a background thread (port 4005, :dont-close t), then calls `start-viewer`
- [x] 1.2 Export `bootstrap` from both `:cl-occt-viewer.impl` and `:cl-occt-viewer` packages in `package.lisp`

## 2. SBCL Core Dump

- [x] 2.1 Create `scripts/make-core.lisp` — loads `:cl-occt-viewer` via ASDF, quickloads `:slynk`, calls `(save-lisp-and-die \"ClotCAD.core\")`
- [x] 2.2 Verify core dumps cleanly (no running threads, no open streams) and loads with `sbcl --core ClotCAD.core --eval t` (requires building project first)

## 3. License Files

- [x] 3.1 Copy GPL-3.0.txt from repo root to `share/licenses/GPL-3.0.txt`
- [x] 3.2 Download and place LGPL-2.1.txt (OCCT) at `share/licenses/LGPL-2.1.txt`
- [x] 3.3 Download and place LGPL-3.0.txt (Qt6) at `share/licenses/LGPL-3.0.txt`
- [x] 3.4 Create `share/licenses/README.md` mapping each component to its license file

## 4. Desktop Entry and Icon

- [x] 4.1 Create `share/ClotCAD.desktop` with Name=ClotCAD, Icon=ClotCAD, Exec=AppRun, Categories=Graphics;CAD;
- [x] 4.2 Convert `share/icons/ClotCAD-logo.svg` to 256x256 PNG at `share/icons/ClotCAD-logo.png` for AppImage

## 5. Launcher Script

- [x] 5.1 Create `run.sh` (same file used as AppRun for AppImage):
  - Detect script directory via `readlink -f`
  - Set `LD_LIBRARY_PATH` to include `lib/qt6`, `lib/qt6/plugins`, `lib/occt`, `lib/`
  - Execute `sbcl/bin/sbcl --core ClotCAD.core --eval '(bootstrap)' --eval '(sb-ext:quit)'`

## 6. Packaging Script

- [x] 6.1 Create `scripts/package.sh` that assembles the `dist/` directory:
  - Copies SBCL core, SBCL runtime, libocctviewer.so, libocctwrap.so, OCCT libs, Qt6 libs + plugins, licenses, desktop file, icon, launcher
  - Discovers OCCT deps via `ldd` on libocctviewer.so + libocctwrap.so
  - Copies Qt6 libs from system `/usr/lib/x86_64-linux-gnu/`
- [x] 6.2 Package as tarball: `tar czf ClotCAD-<version>-x86_64.tar.gz dist/`
- [x] 6.3 Package as AppImage: run `linuxdeploy` then `appimagetool` on `dist/`
- [x] 6.4 Add version detection (from git tag or VERSION file) to output filenames

## 7. Justfile Recipes

- [x] 7.1 Add `core` recipe: run `scripts/make-core.lisp` to produce `ClotCAD.core`
- [x] 7.2 Add `dist` recipe: run `scripts/package.sh` to produce distribution artifacts
- [x] 7.3 Add `package-all` recipe: `core` + `dist` (sets up full pipeline)

## 8. Unit Tests

- [x] 8.1 Add test for `bootstrap` function in `t/viewer-tests.lisp`: verify it calls start-viewer even when Slynk is unavailable
- [x] 8.2 Add test for `scripts/make-core.lisp`: verify bootstrap symbol is defined after loading cl-occt-viewer (save-lisp-and-die can't be mocked due to SBCL package locks)

## 9. CI Pipeline

- [x] 9.1 Create `.github/workflows/release.yml` targeting Ubuntu 24.04:
  - Install system dependencies: `qt6-base-dev`, `libqt6opengl6-dev`, `cmake`, `build-essential`, `curl`
  - Install SBCL 2.6.0 (download from sbcl.org)
  - Install linuxdeploy + appimagetool
  - Restore OCCT from cache (build once, cache `.local/`)
  - Run `just core`
  - Run `just dist`
  - Upload `.AppImage` and `.tar.gz` as artifacts
- [x] 9.2 Add OCCT build caching to avoid rebuilding on every run
- [x] 9.3 Configure workflow to trigger on tag push (`v*`)

## 10. Documentation

- [x] 10.1 Update `README.md` with distribution section:
  - Download links (AppImage, tarball)
  - Quickstart: how to run
  - glibc requirement (2.39+)
  - Link to source code on GitHub (GPL compliance)
- [x] 10.2 Update `justfile` default output and AGENTS.md with new recipes
