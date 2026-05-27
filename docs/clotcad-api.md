# ClotCAD API Reference

ClotCAD is a parametric CAD application built on Common Lisp and OpenCASCADE (OCCT).
Users interact via an in-window REPL or a remote SLY/LSP connection.

## Packages

Functions are available in the `CLOTCAD-USER` package (nicknames: `CAD-USER`, `OCCT-USER`),
which combines `CL-OCCT` (modeling kernel) and `CLOTCAD` (viewer commands).

## 3D Primitives

```lisp
(make-box dx dy dz)                                         ; => shape
(make-cylinder radius height)                               ; => shape
(make-sphere radius)                                        ; => shape
(make-cone r1 r2 height)                                    ; => shape
(make-torus major-radius minor-radius)                      ; => shape
```

## Sweeps

```lisp
(make-prism shape dx dy dz)                                 ; => shape
(make-revol shape ax ay az angle-deg)                       ; => shape
```

`make-prism` extrudes a shape along a vector. `make-revol` revolves a shape around an axis.

## Boolean Operations

```lisp
(cut shape &rest others)                                    ; => shape
(fuse shape &rest others)                                   ; => shape
(common shape &rest others)                                 ; => shape
(section shape &rest others)                                ; => shape
```

`cut` subtracts shapes, `fuse` unions them, `common` intersects, `section` returns intersection curves.
Wrapper functions accept symbols, strings, or raw shapes.

## Transformations

```lisp
(translate shape dx dy dz)                                  ; => shape
(rotate shape ax ay az angle-deg)                           ; => shape
```

## 2D Geometry

### Points, Vectors, Directions

```lisp
(make-pnt2d x y)                                            ; => geom2d
(make-vec2d x y)                                            ; => geom2d
(make-dir2d x y)                                            ; => geom2d
```

### Lines & Circles

```lisp
(make-line2d x y dx dy)                                     ; => geom2d
(make-circle2d x y radius)                                  ; => geom2d
```

### Edges

```lisp
(make-edge x1 y1 x2 y2)                                     ; => shape
(make-edge-3d x1 y1 z1 x2 y2 z2)                            ; => shape
(make-circle-edge x y radius)                               ; => shape
(make-circular-arc x1 y1 x2 y2 x3 y3)                       ; => shape
```

### Wires & Faces

```lisp
(make-wire &rest edges)                                     ; => shape
(make-face wire)                                            ; => shape
(make-face-on-plane wire ox oy oz nx ny nz)                 ; => shape
```

## Object Display Management

```lisp
(display name shape &key visible show-in-tree origin)       ; => shape
(clear-all)                                                 ; => nil
(def name shape-form)                                       ; => shape
(show &rest names)                                          ; => nil
(hide &rest names)                                          ; => nil
(toggle &rest names)                                        ; => nil
(show-defs on)                                              ; => nil
(toggle-defs)                                               ; => nil
(resolve-shape designator)                                  ; => shape
```

`display` shows a shape in the 3D scene and registers it in the DAG registry for future reference.
`def` evaluates a shape form, stores it in the DAG registry, and shows it grayed in the Scene Tree.
`show`/`hide`/`toggle` control visibility by name. `resolve-shape` resolves a symbol, string, or raw value to a shape object from the DAG registry.

## Selection

```lisp
(select &rest designators)                                  ; => nil
(deselect &rest designators)                                ; => nil
(clear-selection)                                           ; => nil
(selected-shapes)                                           ; => list
(apply-selection-schemes &key click ctrl-click shift-click) ; => nil
```

## Subshape Queries

Find faces, edges, and vertices by spatial and topological properties.

```lisp
(query-shape designator &key where coordinate-system)              ; => list
```

`query-shape` resolves the designator, enumerates all faces, edges, and
vertices, then applies each predicate closure in `where` left-to-right
as a pipeline. Each predicate is a function that returns a closure —
use `(list ...)` to combine them.

### Predicate Constructors

Each predicate constructor returns a closure suitable for use in `:where`.

```lisp
(face-p)                                                           ; => closure
(edge-p)                                                           ; => closure
(vertex-p)                                                         ; => closure
(surface-type :plane)                                              ; => closure
(curve-type :circle)                                               ; => closure
(normal-along dx dy dz &key angle-deg)                             ; => closure
(edge-along dx dy dz &key angle-deg)                               ; => closure
(longer-than value)                                                ; => closure
(shorter-than value)                                               ; => closure
(larger-than value)                                                ; => closure
(smaller-than value)                                               ; => closure
(x-center value &key tolerance)                                    ; => closure
(y-center value &key tolerance)                                    ; => closure
(z-center value &key tolerance)                                    ; => closure
(radius-around value &key tolerance)                               ; => closure
(max-by function)                                                  ; => closure
(min-by function)                                                  ; => closure
```

Spatial predicates accept `:angle-deg` (default 1°) and `:tolerance` (default 1e-6).

### Convenience Accessors

```lisp
(top-face designator)                                              ; => face
(bottom-face designator)                                           ; => face
(longest-edge designator)                                          ; => edge
(shortest-edge designator)                                         ; => edge
(largest-face designator)                                          ; => face
(smallest-face designator)                                         ; => face
```

### Examples

```lisp
;; Top face of a box
(query-shape (make-box 10 20 30) :where (list (face-p) (normal-along 0 0 1)))
=> (#<FACE ...>)

;; Longest edge
(longest-edge (make-box 10 20 30))
=> #<EDGE ...>

;; Largest planar face with normal in +Z (same as top-face)
(query-shape :my-box :where
  (list (face-p) (surface-type :plane) (normal-along 0 0 1) (max-by #'face-area)))
=> (#<FACE ...>)

;; Circular edges near radius 5
(query-shape (make-cylinder 5 20)
             :where (list (edge-p) (radius-around 5 :tolerance 0.1)))
=> (#<EDGE ...> #<EDGE ...>)
```

## Compounds & Assemblies

```lisp
(make-compound shapes)                                      ; => shape
(add-to-compound compound shape)                            ; => shape
(make-part shape &key name color location)                  ; => shape
(make-assembly &key name children)                          ; => assembly
```

## View Controls

```lisp
(set-view orientation)                                      ; => nil
(current-view)                                              ; => keyword
(fit-view)                                                  ; => nil
(set-view-aa enable)                                        ; => nil
```

Orientation values: `:top`, `:bottom`, `:front`, `:back`, `:left`, `:right`, `:iso`.

### Grid, Axis, ViewCube Toggles

```lisp
(show-grid &optional show)                                  ; => nil
(toggle-grid)                                               ; => nil
(show-axis &optional show)                                  ; => nil
(toggle-axis)                                               ; => nil
(show-viewcube &optional show)                              ; => nil
(toggle-viewcube)                                           ; => nil
(show-viewcube-axes &optional show)                         ; => nil
(toggle-viewcube-axes)                                      ; => nil
(set-viewcube-font-height height)                            ; => height
(set-trihedron-font-size size)                               ; => size
```

`set-viewcube-font-height` sets the ViewCube label font height in logical pixels (auto-scaled for high-DPI displays). Default: 16. `set-trihedron-font-size` sets the trihedron axis label font size in logical pixels (auto-scaled for high-DPI). Default: 16. Both are also settable via theme palette keys `:viewcube-font-height` and `:trihedron-font-size`.

## Dock Panels

```lisp
(show-repl &optional show)                                  ; => nil
(toggle-repl)                                               ; => nil
(show-scene-tree &optional show)                            ; => nil
(toggle-scene-tree)                                         ; => nil
```

## Theme

```lisp
(apply-theme mode &key accent)                              ; => nil
(theme-dark &optional accent)                               ; => nil
(theme-light &optional accent)                              ; => nil
(theme-auto &optional accent)                               ; => nil
(set-accent color-hex)                                      ; => nil
(set-font-size size)                                        ; => nil
```

Mode values: `:dark`, `:light`, `:auto`. Accent is a hex color string like `"#4A90D9"`.

## Parametric DSL

The DSL provides a reactive DAG (directed acyclic graph) for parametric modeling.
Models auto-track dependencies and re-evaluate when parameters change.

### Macros

```lisp
(defmodel name (params) ..body)                             ; => model
(with-params (&rest bindings) ..body)                       ; => values
```

### Functions

```lisp
(param key)                                                 ; => value
(model-ref name)                                            ; => shape
(model-color name)                                          ; => color or nil
(model-display-name name)                                   ; => string or nil
(model-layer name)                                          ; => string or nil
```

### Variables

```lisp
*params*                       ; global parameter plist
*model-registry*               ; DAG model registry hash table
```

### Mutation

```lisp
(set-param! key value)                                      ; => value
(set-params! &rest key-values)                              ; => params plist
```

### Examples

```lisp
;; Simple parameterized model
(defmodel base-plate (w d)
  (make-box (param :w) 5 (param :d)))

;; Model referencing another model
(defmodel assembly (h)
  (fuse (model-ref :base-plate)
        (make-cylinder 5 (param :h))))

;; Model with let, boolean cut, and translate
(defmodel bracket (w h d r)
  (let ((box (make-box (param :w) (param :h) (param :d)))
        (hole (make-cylinder (param :r) (param :d))))
    (cut box (translate hole
      (/ (param :w) 2) (/ (param :h) 2) 0))))

;; Set global parameters
(set-params! :w 60 :d 40 :h 20 :r 3)

;; Display assembly directly
(display :assy (model-ref :assembly))

;; Local parameter scope with def/show workflow
(with-params (:w 80 :h 30)
  (def :br (model-ref :bracket)))
(show :br)

;; Fit view to see all shapes
(fit-view)
```

## File I/O

```lisp
(write-step shape filename)                                 ; => nil
(read-step filename)                                        ; => shape
(write-stl shape filename &key deflection)                  ; => nil
(read-stl filename)                                         ; => shape

;; DAG registry I/O (with metadata):
(write-dag-models-to-step path)                             ; => nil
(read-step-into-dag path)                                   ; => assembly
```

## Introspection

```lisp
(doc name)                                                  ; => nil
(apropos &optional pattern &key packages case-insensitive)  ; => nil
```

`doc` prints the documentation string and arglist (if applicable) for any symbol, string, or function object. Works with functions, macros, variables, types, structures, and CLOS classes without requiring a type argument.

`apropos` has three modes:

**Category tree** (no argument): `(apropos)` lists every capability category derived from source file introspection, with function counts and representative function names. This is the primary discovery mechanism — see what the system can do without needing to know function names.

**Keyword category lookup**: `(apropos :fillet)` shows all functions in a category with full signatures and docstrings. The keyword is matched partially and case-insensitively against display names and filename stems — `:file` matches "File I/O", `:face` matches both "Faces" and "Face Filling". If multiple categories match, a filtered list is shown. If no category matches, prints "No category found" (no fallthrough to substring search).

**Substring search** (string or bare symbol): `(apropos "box")` or `(apropos box)` — existing behavior. Searches for external symbols matching a substring. By default searches only `:clotcad` and `:cl-occt` packages. Use `:packages t` for all packages, or `:packages :cl-occt` / `:packages '(:cl-occt :clotcad)` for specific packages. Results are grouped by package with type annotations.

## Help

```lisp
(help)                                                      ; => values
```

## REPL & Import

```lisp
(cancel-import)                                             ; => nil
(replay-speed ms)                                           ; => nil
(result-export flag)                                        ; => nil
(export-repl-history path)                                  ; => nil
(set-repl-history-key modifier)                             ; => nil
(set-repl-submit-key modifier)                              ; => nil
```

Modifier values: `:ctrl`, `:none`, `:alt`.

## Typical Workflow

```lisp
;; 1. Create and display a shape
(display :box (make-box 10 20 30))

;; 2. Named shape workflow (def → show)
(def :s (make-sphere 20))
(def :b (make-box 10 20 30))
(def :result (cut :s :b))
(show :result)

;; 3. Visibility control
(hide :result)
(toggle :result)

;; 4. Selection
(select :box :sphere)
(selected-shapes)  ;; => ("BOX" "SPHERE")

;; 5. View control
(set-view :iso)
(fit-view)

;; 6. Export
(write-step :result "output.step")
```

## Threading Macros

Convenience macros for writing nested function calls as linear pipelines. Inspired by Clojure's threading macros.

### Thread-first (->)

Inserts the previous result as the first argument of each form.

```lisp
(-> 1 (+ 2) (* 3) (- 4))               ; => 5
(-> 5 sqrt float)                       ; => 2.236068
(-> 42 list)                            ; => (42)
```

### Thread-last (->>)

Inserts the previous result as the last argument of each form.

```lisp
(->> '(1 2 3) (mapcar #'1+) (remove-if #'evenp))   ; => (3)
(->> 3 (expt 2))                                    ; => 8
(->> 5 (list 1 2))                                  ; => (1 2 5)
```

### Thread-as (as->)

Threads a value through forms using a named binding. Each form's result is bound to the name for the next form.

```lisp
(as-> (list :foo :bar) v
  (mapcar #'symbol-name v)
  (first v)
  (char v 0))
;; => #\F
```

Bare symbols as forms are called with the threaded value as their single argument (applies to both `->` and `->>`).

## Viewer Interaction

| Action | Mouse |
|--------|-------|
| Orbit | Left mouse button |
| Pan | Middle mouse button |
| Zoom | Right mouse button / scroll |
| ViewCube | Click faces/corners for one-click orientation |
| Scene Tree | Click to select, Ctrl+click to toggle, Shift+click for range |

### REPL Key Bindings

| Key | Action |
|-----|--------|
| Enter | Submit expression |
| Shift+Enter | Insert newline |
| Ctrl+Up | Previous history entry |
| Ctrl+Down | Next history entry |
| Tab | Insert 2-space indent |
