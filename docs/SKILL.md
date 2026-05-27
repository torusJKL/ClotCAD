---
name: clotcad
description: Interact with ClotCAD 3D CAD application via slyc. Create, display, inspect, boolean-operate, transform, and export 3D shapes programmatically. Use when working with ClotCAD, CAD modeling, parametric design, or exporting STEP/STL from the viewer. Covers connecting, headless startup, shape creation, geometry queries (for visionless agents), error handling, and API discovery via doc/browse/help.
---

# Skill: ClotCAD — CAD via Lisp and slyc

ClotCAD is a parametric 3D CAD application with a Common Lisp API built on
OpenCASCADE (OCCT). AI agents interact with it programmatically via `slyc`,
a CLI client for Slynk REPL servers.

**Download slyc**: https://github.com/torusJKL/slyc

## Connecting

### To a running ClotCAD instance

```bash
slyc --package CLOTCAD-USER --port 4005 "<lisp-form>"
```

`CLOTCAD-USER` (nicknames: `CAD-USER`, `OCCT-USER`) uses `:cl`, `:cl-occt`,
and `:clotcad` — all modeling and viewer functions are available.

### Headless startup (no GUI window)

```bash
./ClotCAD.AppImage --slynk
```

This starts ClotCAD in headless mode with Slynk on port 4005. Connect via `slyc`.
The `bootstrap` function starts both Slynk (4005) and Alive LSP (4006) automatically
in GUI mode.

### Exit codes from slyc

| Code | Meaning |
|------|---------|
| 0 | Success — result on stdout |
| 1 | Lisp error — condition text on stdout |
| 2 | Connection/protocol error — details on stderr |
| 124 | Timeout — form did not complete in time |

## Core CAD Workflow (no vision)

An agent cannot see the 3D viewport. Every operation is verified
programmatically — by check counts, query results, and error detection.

### Lifecycle

```lisp
(bootstrap)       ; Start viewer + Slynk(4005) + Alive LSP(4006)
(start-viewer)    ; Launch just the viewer window
(stop-viewer)     ; Close the viewer
(quit-clotcad)    ; Exit everything
```

### Create and display shapes

```lisp
;; Primitives — each returns a shape object
(make-box 10 20 30)           ; => #<SHAPE ...>
(make-cylinder 5 20)          ; => #<SHAPE ...>
(make-sphere 10)              ; => #<SHAPE ...>
(make-cone 10 5 30)           ; => #<SHAPE ...>
(make-torus 20 5)             ; => #<SHAPE ...>

;; Register and display
(display :box (make-box 10 20 30))    ; name + shape -> visible in viewport
(def :box (make-box 10 20 30))        ; define without displaying
(show :box)                            ; make visible
(hide :box)                            ; hide
(toggle :box)                          ; toggle visibility
(clear-all)                            ; remove everything
```

### Boolean and transform operations

All return **new shapes** — no mutation.

```lisp
(cut A B)        ; subtract B from A
(fuse A B)       ; union A and B
(common A B)     ; intersect A and B
(section A B)    ; intersection curves

(translate shape dx dy dz)       ; move by vector
(rotate shape ax ay az deg)      ; rotate around axis by degrees
(make-prism shape dx dy dz)      ; extrude along vector
(make-revol shape ax ay az deg)  ; revolve around axis
(make-compound list-of-shapes)   ; group into one shape
```

### Inspect a shape

```lisp
(shape-type my-shape)   ; => :SOLID, :FACE, :EDGE, :VERTEX, :WIRE, :SHELL, etc.
```

### View control

```lisp
(set-view :top)      ; looking down Z axis (X-Y plane)
(set-view :bottom)   ; looking up Z axis
(set-view :front)    ; looking in -Y direction (X-Z plane)
(set-view :back)     ; looking in +Y direction
(set-view :left)     ; looking in -X direction (Y-Z plane)
(set-view :right)    ; looking in +X direction
(set-view :iso)      ; isometric
(fit-view)           ; fit all shapes into viewport
(current-view)       ; query current orientation -> :TOP, NIL, etc.
```

### Export

```lisp
(write-step :my-box "output.step")
(write-stl :my-box "output.stl")
(write-stl :my-box "output.stl" :deflection 0.01)   ; finer mesh
```

> **Only visible objects are exported** when using File > Export (STEP/STL) from the
> menu — this calls `export-all-step`/`export-all-stl` internally which iterates
> `*displayed-models*`. Per-shape `write-step`/`write-stl` work on any shape
> regardless of visibility.

## Inspecting Geometry Without Vision

Since you can't see the viewport, use subshape queries to inspect geometry
programmatically. This is how you "look at" shapes.

### Convenience accessors

```lisp
(top-face :my-box)        ; top-most planar face (+Z normal)
(bottom-face :my-box)     ; bottom-most planar face (-Z normal)
(longest-edge :my-box)    ; edge with maximum length
(shortest-edge :my-box)   ; edge with minimum length
(largest-face :my-box)    ; face with maximum area
(smallest-face :my-box)   ; face with minimum area
```

### query-shape — the general inspection tool

```lisp
(query-shape designator :where (list predicate1 predicate2 ...))
```

Resolves the shape, collects all subshapes, then applies predicates left-to-right
as a pipeline. Each predicate filters or selects.

**Predicate factories** (each returns a closure):

| Type filters | Geometry filters | Selection |
|---|---|---|
| `(face-p)` | `(normal-along dx dy dz &key angle-deg)` | `(max-by fn)` |
| `(edge-p)` | `(edge-along dx dy dz &key angle-deg)` | `(min-by fn)` |
| `(vertex-p)` | `(surface-type :plane/:cylinder/:cone/:sphere/:torus)` | |
| | `(curve-type :line/:circle/:ellipse)` | |
| | `(longer-than val)` `(shorter-than val)` | |
| | `(larger-than val)` `(smaller-than val)` | |
| | `(x-center val &key tolerance)` | |
| | `(y-center val &key tolerance)` | |
| | `(z-center val &key tolerance)` | |
| | `(radius-around val &key tolerance)` | |

Examples:

```lisp
;; Find all faces with normal in +Z
(query-shape (make-box 10 20 30)
  :where (list (face-p) (normal-along 0 0 1)))
;; => (#<FACE ...>)

;; Find the top face (same as top-face)
(query-shape :my-box
  :where (list (face-p) (normal-along 0 0 1) (max-by #'z-center)))

;; Find circular edges near radius 5
(query-shape (make-cylinder 5 20)
  :where (list (edge-p) (radius-around 5 :tolerance 0.1)))

;; Find edges longer than 15mm
(query-shape :my-box
  :where (list (edge-p) (longer-than 15)))
```

### Named subshapes — stable references

Named subshapes survive shape recomputation (e.g. after parameter changes).
They appear as children of their parent in the scene tree.

```lisp
;; Register a named query
(name-subshape :my-box :top-face
  :where (list (face-p) (normal-along 0 0 1) (max-by #'z-center)))
;; => :TOP-FACE

;; Resolve later — re-evaluates the query each time
(face-ref :my-box :top-face)       ; => #<FACE ...>
(edge-ref :my-box :longest-edge)   ; => #<EDGE ...>

;; Use compound symbols in any designator position
(show :my-box/top-face)            ; show the child in the scene tree
(hide :my-box/top-face)

;; List and remove
(list-named-subshapes :my-box)
(remove-named-subshape :my-box :top-face)
```

## Error Handling

Errors are caught **silently** by the global debugger hook — they never abort
the Lisp process. This means you must **actively check** whether an operation
succeeded.

> **Key insight**: `*debugger-invocation-count*` is a counter incremented on
> every caught condition. Compare its value before and after an operation
> to detect silent failures.

### The check pattern

```lisp
;; 1. Record starting count
(let ((before *debugger-invocation-count*))
  ;; 2. Do work
  (display :result (cut (make-box 10 10 10) (make-sphere 8)))
  ;; 3. Compare after
  (if (> *debugger-invocation-count* before)
      (progn
        (format t "~&Silent error detected. Showing last 5:~%")
        (show-errors 5))
      (format t "~&OK — no errors.")))
```

### Commands

```lisp
*debugger-invocation-count*      ; variable — check for silent errors
(show-errors &optional (n 5))    ; print last N errors from the log
(abort-all-threads)              ; recover stuck threads
(abort-stuck-threads)            ; abort only threads in *stuck-threads*
```

### REPL commands (prefix with `,`)

| Command | What it does |
|---|---|
| `,errors [N]` | Show last N errors (default 5) |
| `,abort` | Abort all stuck threads |
| `,debug` | Show stuck threads with their conditions |
| `,help` | List available commands |

## Finding What You Need

Don't rely on this skill being exhaustive. Use ClotCAD's introspection tools
to discover and explore the full API.

### help — quick start

```lisp
(help)
;; => Prints overview with basic examples
```

### browse — API catalog

Three modes:

```lisp
(browse)                        ; category tree — see what exists
(browse :primitives)            ; drill into one category
(browse "box")                  ; substring search across exports
```

Categories include: `:primitives`, `:booleans`, `:fillet`, `:chamfer`, `:transforms`,
`:sweep`, `:loft`, `:faces`, `:topology`, `:compounds`, `:assembly`, `:io`,
`:mass-properties`, `:shape-analysis`, `:curves`, `:geom2d`, and more.

Search options:

```lisp
(browse "box")                                    ; search :clotcad + :cl-occt
(browse "box" :packages t)                         ; search all packages
(browse "box" :packages :cl-occt)                  ; search only cl-occt
(browse "box" :packages '(:cl-occt :clotcad))     ; specific packages
(browse "Box" :case-insensitive nil)               ; case-sensitive search
```

### doc — detailed reference

```lisp
(doc make-box)         ; bare symbol (auto-quoted)
(doc "make-box")       ; string — searched in :clotcad then :cl-occt
(doc #'make-box)       ; function object
```

Prints: package-qualified name, argument list, and docstring.

## Example Workflow

```lisp
;; 1. Create and display
(display :plate (make-box 100 60 10))

;; 2. Inspect without vision
(top-face :plate)
=> #<FACE ...>

;; 3. Add features
(display :hole (translate (make-cylinder 5 15) 50 30 -5))
(display :result (cut :plate :hole))

;; 4. Set view
(set-view :iso)
(fit-view)

;; 5. Export
(write-step :result "plate.step")
```

## Quick Reference

| Task | Form |
|---|---|
| Create box | `(make-box dx dy dz)` |
| Create cylinder | `(make-cylinder r h)` |
| Create sphere | `(make-sphere r)` |
| Display shape | `(display :name shape)` |
| Show/hide | `(show :name)`, `(hide :name)` |
| Boolean cut | `(cut A B)` |
| Boolean fuse | `(fuse A B)` |
| Translate | `(translate shape dx dy dz)` |
| Rotate | `(rotate shape ax ay az deg)` |
| Top face | `(top-face :name)` |
| Longest edge | `(longest-edge :name)` |
| Query subshapes | `(query-shape :name :where (list ...))` |
| Set view | `(set-view :iso)` |
| Fit all | `(fit-view)` |
| Check errors | `*debugger-invocation-count*` |
| Show errors | `(show-errors 10)` |
| Export STEP | `(write-step :name "file.step")` |
| Export STL | `(write-stl :name "file.stl")` |
| Explore API | `(browse)`, `(browse :category)`, `(browse "str")` |
| Get docs | `(doc symbol)` |
