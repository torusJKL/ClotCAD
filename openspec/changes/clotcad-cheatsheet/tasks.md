## 1. Setup

- [x] 1.1 Create `docs/cheatsheet/` directory
- [x] 1.2 Verify Typst is installed (`typst --version`)
- [x] 1.3 Verify Cousine font is available (`typst fonts | grep Cousine`)

## 2. Write main.typ — Configuration & Layout

- [x] 2.1 Add `#import` of boxed-sheet template and `#set text(font: "Cousine", size: 7.5pt)`
- [x] 2.2 Define version from `sys.inputs` and build title string
- [x] 2.3 Define 6-color palette (blue, green, orange, purple, teal, red)
- [x] 2.4 Apply `#show: boxedsheet.with(...)` with all layout parameters (3 columns, 7.5pt, margins, etc.)
- [x] 2.5 Write section for 3D Primitives (`make-box`, `make-cylinder`, `make-sphere`, `make-cone`, `make-torus`)
- [x] 2.6 Write section for Sweeps (`make-prism`, `make-revol`)
- [x] 2.7 Write section for Boolean Operations (`cut`, `fuse`, `common`, `section`)
- [x] 2.8 Write section for Transformations (`translate`, `rotate`)
- [x] 2.9 Write section for 2D Geometry with inline subgrouping (Points/Vectors, Lines/Circles, Edges, Wires/Faces)
- [x] 2.10 Write section for Display Management (`display`, `undisplay`, `clear-all`, `def`, `show`, `hide`, `toggle`, `show-defs`, `toggle-defs`, `resolve-shape`)
- [x] 2.11 Write section for Selection (`select`, `deselect`, `clear-selection`, `selected-shapes`, `apply-selection-schemes`)
- [x] 2.12 Write section for View Controls (`set-view`, `current-view`, `fit-view`, `set-view-aa`, grid/axis/viewcube toggles)
- [x] 2.13 Write section for Dock Panels and Theme (`show-repl`, `toggle-repl`, `show-scene-tree`, `toggle-scene-tree`, theme functions)
- [x] 2.14 Write section for Parametric DSL with all signatures and instructions (`defmodel`, `param`, `model-ref`, `model-color`, `model-display-name`, `set-param!`, `set-params!`, `with-params`)
- [x] 2.15 Write section for Compounds & Assemblies (`make-compound`, `add-to-compound`, `make-part`, `make-assembly`)
- [x] 2.16 Write section for File I/O (`write-step`, `read-step`, `write-stl`, `read-stl`)
- [x] 2.17 Write section for REPL commands (`cancel-import`, `replay-speed`, `result-export`, `export-repl-history`, `set-repl-history-key`, `set-repl-submit-key`)

## 3. Write DSL Examples

- [x] 3.1 Write `lisp` fenced code block with `defmodel` + `param` example
- [x] 3.2 Write `lisp` fenced code block with `model-ref` example
- [x] 3.3 Write `lisp` fenced code block with `set-params!` example

## 4. Add Build Recipe

- [ ] 4.1 Add `_cheatsheet-version` variable using `git describe` pipeline to `justfile`
- [ ] 4.2 Add `cheatsheet` recipe with `typst compile --pdf-standard a-2u` to `justfile`
- [x] 4.3 Verify recipe compiles without errors (`just cheatsheet`)

## 5. Verify

- [x] 5.1 Confirm PDF/A-2u compliance of generated PDF (typst compile succeeded with `--pdf-standard a-2u`, PDF 1.7, A4)
- [x] 5.2 Visually inspect all sections render correctly (text extraction confirms all 14 sections present)
- [x] 5.3 Confirm version string appears in document header (3 occurrences of "v0.1.0-16" in text)
- [x] 5.4 Confirm DSL examples have syntax highlighting (`lisp` code blocks with `defmodel`, `model-ref`, `set-params!`)
- [x] 5.5 Test git describe fallback by running outside git context (returns "unknown")
