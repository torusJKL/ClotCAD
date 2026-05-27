## 1. Create the SKILL.md

- [x] 1.1 Create `docs/SKILL.md` with Connecting section covering slyc usage, port, package, and headless startup with `ClotCAD.AppImage --slynk`
- [x] 1.2 Add Core CAD Workflow section covering lifecycle (`bootstrap`, `start-viewer`, `quit-clotcad`), shape creation (`make-box`, `make-cylinder`, `make-sphere`, `make-cone`, `make-torus`), display (`display`, `def`), and visibility (`show`, `hide`, `toggle`, `clear-all`)
- [x] 1.3 Add Inspecting Geometry Without Vision section covering `shape-type`, `query-shape` with predicate factories (`face-p`, `edge-p`, `vertex-p`, `normal-along`, `surface-type`, `curve-type`, `longer-than`, `shorter-than`, `larger-than`, `smaller-than`, `max-by`, `min-by`), convenience accessors (`top-face`, `bottom-face`, `longest-edge`, `largest-face`), and named subshapes (`name-subshape`, `face-ref`, `edge-ref`)
- [x] 1.4 Add Boolean and Transform Operations section covering `cut`, `fuse`, `common`, `section`, `translate`, `rotate`, `make-prism`, `make-revol`, `make-compound`, `make-part`
- [x] 1.5 Add Error Handling section covering `*debugger-invocation-count*` (check-before/after pattern), `show-errors`, `abort-all-threads`, and `abort-stuck-threads`
- [x] 1.6 Add Export section covering `write-step` and `write-stl` with note that only visible objects export via File menu but per-shape functions work on any shape
- [x] 1.7 Add Finding What You Need section covering `doc`, `browse` (no-args, keyword, string modes), `help`, and category exploration patterns
- [x] 1.8 Add View Control section covering `set-view`, `current-view`, `fit-view`, `show-grid`, `show-axis`
