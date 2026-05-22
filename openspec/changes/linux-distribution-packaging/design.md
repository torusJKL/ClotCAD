## Context

ClotCAD is a Qt6 + OCCT + SBCL polyglot application. Currently it runs via `just start` which builds OCCT, builds the C++ wrapper, and loads everything via SBCL's `--script` with ASDF. Distribution has meant "clone the repo and run just setup."

The application has three runtime dependency layers:
1. **System**: OpenGL (driver, always present)
2. **C++ libraries**: Qt6 (Widgets, OpenGLWidgets), OCCT 8.0.0 (20+ shared libs), plus ClotCAD's own `libocctviewer.so` and cl-occt's `libocctwrap.so`
3. **Lisp runtime**: SBCL 2.6.0 + Slynk

All three layers will be bundled.

## Goals / Non-Goals

**Goals:**
- Single `.AppImage` file that runs on any Linux distribution (glibc 2.39+)
- `.tar.gz` archive with identical contents
- Pre-compiled SBCL core for sub-second startup
- Slynk server on port 4005 for SLIME/SLY connectivity (started in background thread)
- All licenses bundled with clear mapping
- CI pipeline (GitHub Actions) building both artifacts on Ubuntu 24.04

**Non-Goals:**
- Flatpak/Snap/other Linux packaging formats
- Distribution packages (.deb, .rpm)
- macOS or Windows distribution
- nREPL support
- Automatic update mechanism
- Code signing

## Decisions

### 1. Single dist/ directory for both formats

The AppImage AppDir and tarball contents are identical. The build script assembles `dist/` once, then either runs `appimagetool` on it or tars it up. This eliminates duplication and ensures consistency.

Resulting `dist/` layout:
```
dist/
├── ClotCAD.core         # SBCL heap image
├── sbcl/bin/sbcl            # SBCL runtime 2.6.0
├── lib/
│   ├── libocctviewer.so     # C++ wrapper
│   ├── libocctwrap.so       # cl-occt C bridge
│   ├── occt/                # OCCT shared libs
│   │   ├── libTKernel.so*
│   │   ├── libTKMath.so*
│   │   └── ...
│   └── qt6/                 # Qt6 shared libs + plugins
│       ├── libQt6Core.so.6
│       ├── libQt6Gui.so.6
│       ├── libQt6Widgets.so.6
│       ├── libQt6OpenGL.so.6
│       ├── libQt6OpenGLWidgets.so.6
│       └── plugins/platforms/libqxcb.so
├── share/
│   ├── licenses/
│   │   ├── README.md        # maps components to licenses
│   │   ├── GPL-3.0.txt      # ClotCAD
│   │   ├── LGPL-2.1.txt     # OCCT
│   │   └── LGPL-3.0.txt     # Qt6
│   └── icons/ClotCAD-logo.svg
├── ClotCAD.desktop      # AppDir metadata
├── ClotCAD.png           # 256x256 icon (matches Icon= in desktop)
├── .DirIcon                  # copy of icon (AppImage spec)
├── usr/share/icons/hicolor/256x256/apps/
│   └── ClotCAD.png       # standard freedesktop path
└── run.sh                    # launcher (AppRun for AppImage)
```

### 2. SBCL core dump over source loading

Instead of shipping Lisp source and loading via `--script`, we dump a heap image with `save-lisp-and-die`. This:
- Eliminates ASDF/Quicklisp loading at startup (sub-second)
- Removes need for Quicklisp in the bundle
- Ships one known-good SBCL version (2.6.0)

The core is built by `scripts/make-core.lisp`:
```lisp
(load-system :cl-occt-viewer)
(ql:quickload :slynk)  ; not loaded by cl-occt-viewer
(save-lisp-and-die "ClotCAD.core")
```

At runtime, the launcher runs:
```bash
sbcl --core ClotCAD.core \
     --eval '(bootstrap)' \
     --eval '(sb-ext:quit)'
```

The `bootstrap` function (added to `lifecycle.lisp`) starts Slynk in a background thread, then calls the existing `start-viewer`.

### 3. Qt6 bundling via CI apt packages

Qt6 is copied from the CI runner's system installation (`/usr/lib/x86_64-linux-gnu/libQt6*.so.6` + plugins). We do not use linuxdeploy-plugin-qt — instead, a simple `cp` in the packaging script copies exactly the needed libs. This avoids adding linuxdeploy as a dependency for the tarball path.

For AppImage specifically, `linuxdeploy` + `appimagetool` are still used to produce the SquashFS wrapper, but Qt detection is handled manually.

### 4. Launcher detects Qt6 automatically

The same `run.sh`/`AppRun` works for both formats:
```bash
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/lib/qt6:$HERE/lib/qt6/plugins:$HERE/lib/occt:$HERE/lib"
exec "$HERE/sbcl/bin/sbcl" --core "$HERE/ClotCAD.core" \
      --eval '(bootstrap)' --eval '(sb-ext:quit)'
```

### 5. License mapping via README

Rather than modifying license texts, a `share/licenses/README.md` maps each component to its license file:
```markdown
ClotCAD                    → GPL-3.0.txt
  https://github.com/.../clotcad

Open CASCADE Technology    → LGPL-2.1.txt
  https://dev.opencascade.org/

Qt6                        → LGPL-3.0.txt
  https://www.qt.io/
```

### 6. linuxdeploy + appimagetool for AppImage

The AppImage is produced by running `linuxdeploy` (with manual Qt lib copying) then `appimagetool` on the `dist/` directory. No linuxdeploy plugins needed since we handle Qt ourselves.

## Risks / Trade-offs

- **glibc compatibility**: Bundled Qt6 from Ubuntu 24.04 links against glibc 2.39. Users on older distros (glibc < 2.39) cannot run the AppImage or full tarball. Mitigation: document minimum glibc requirement. If this becomes a problem, build Qt6 from source on Ubuntu 20.04 CI.
- **SBCL core tied to version**: The `.core` file is specific to SBCL 2.6.0. If the bundled SBCL is updated, the core must be regenerated. Mitigation: pin SBCL version in CI and regenerate on every release build.
- **OCCT library subset**: Only the OCCT libs needed for Visualization + DataExchange are bundled (~79 MB). If cl-occt requires additional modules, the bundle must be updated. Mitigation: use `ldd` on `libocctwrap.so` at build time to discover actual dependencies.
- **AppImage size**: ~170 MB download. Mitigation: document this in release notes; xz compression helps marginally.
