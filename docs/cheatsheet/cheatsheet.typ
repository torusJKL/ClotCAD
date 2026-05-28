#import "@preview/boxed-sheet:0.1.2": *

#set text(font: ("Cousine", "Liberation Mono"))

#let _version = sys.inputs.at("version", default: "dev")
#let _title = "ClotCAD Cheatsheet " + _version

#let cad-colors = (
  rgb("#4A90D9"),
  rgb("#50B86C"),
  rgb("#E67E22"),
  rgb("#9B59B6"),
  rgb("#1ABC9C"),
  rgb("#E74C3C"),
)

#show: boxedsheet.with(
  title: _title,
  authors: "ClotCAD",
  write-title: true,
  title-align: left,
  title-number: true,
  font-size: 10pt,
  line-skip: 12pt,
  x-margin: 18pt,
  y-margin: 28pt,
  num-columns: 3,
  column-gutter: 6pt,
  color-box: cad-colors,
)

= 3D Primitives
#concept-block[
  `make-box(dx, dy, dz)`\
  `make-cylinder(radius, height)`\
  `make-sphere(radius)`\
  `make-cone(r1, r2, height)`\
  `make-torus(major-radius, minor-radius)`\
]

= Sweeps
#concept-block[
  `make-prism(shape, dx, dy, dz)`\
  `make-revol(shape, ax, ay, az, angle-deg)`\
]

= 3D Text
#concept-block[
  `make-3d-text(string, ..options)`\
  #v(2pt)
  #inline("Options")\
  `:font` - name string or auto-fallback\
  `:size` - font size (default 10)\
  `:thickness` - extrusion depth (default 5)\
  `:plane` - :xy, :xz(default), :yz, face, frame\
  `:h-align` - :left, :center(default), :right\
  `:v-align` - :bottom, :center(default), :top\
]

= Boolean Operations
#concept-block[
  `cut(shape, &rest others)`\
  `fuse(shape, &rest others)`\
  `common(shape, &rest others)`\
  `section(shape, &rest others)`\
]

= Transformations
#concept-block[
  `translate(shape, dx, dy, dz)`\
  `rotate(shape, ax, ay, az, angle-deg)`\
]

= 2D Geometry
#concept-block[
  #inline("Points & Vectors")\
  `make-pnt2d(x, y)`\
  `make-vec2d(x, y)`\
  `make-dir2d(x, y)`\

  #inline("Lines & Circles")\
  `make-line2d(x, y, dx, dy)`\
  `make-circle2d(x, y, radius)`\

  #inline("Edges")\
  `make-edge(x1, y1, x2, y2)`\
  `make-edge-3d(x1, y1, z1, x2, y2, z2)`\
  `make-circle-edge(x, y, radius)`\
  `make-circular-arc(x1, y1, x2, y2, x3, y3)`\

  #inline("Wires & Faces")\
  `make-wire(&rest edges)`\
  `make-face(wire)`\
  `make-face-on-plane(wire, ox, oy, oz, nx, ny, nz)`\
]

= Object Display Management
#concept-block[
  `display(name, shape, ..options)`\
  `clear-all()`\
  `def(name, shape-form)`\
  `show(&rest names)`\
  `hide(&rest names)`\
  `toggle(&rest names)`\
  `show-defs(on)`\
  `toggle-defs()`\
  `resolve-shape(designator)`\
]

= Selection
#concept-block[
  `select(&rest designators)`\
  `deselect(&rest designators)`\
  `clear-selection()`\
  `selected-shapes()`\
  `apply-selection-schemes(..schemes)`\
]

= Compounds & Assemblies
#concept-block[
  `make-compound(shapes)`\
  `add-to-compound(compound, shape)`\
  `make-part(shape, ..options)`\
  `make-assembly(..options)`\
]

= Parametric DSL
#concept-block[
  #inline("Macros")\
  `defmodel(name, (params), ..body)`\
  `with-params((&rest bindings), ..body)`\

  #inline("Functions")\
  `param(key)`\
  `model-ref(name)`\
  `model-color(name)`\
  `model-display-name(name)`\
  `model-layer(name)`\

  #inline("Variables")\
  `*params*` — parameter plist\
  `*model-registry*` — DAG registry\

  #inline("Mutation")\
  `set-param!(key, value)`\
  `set-params!(&rest key-values)`\

  #v(4pt)
  #inline("Examples")

  ```lisp
  (defmodel base-plate (w d)
    (make-box (param :w) 5 (param :d)))

  (defmodel assembly (h)
    (fuse (model-ref :base-plate)
          (make-cylinder 5 (param :h))))

  (defmodel bracket (w h d r)
    (let ((box (make-box (param :w) (param :h) (param :d)))
          (hole (make-cylinder (param :r) (param :d))))
      (cut box (translate hole
        (/ (param :w) 2) (/ (param :h) 2) 0))))

  (set-params! :w 60 :d 40 :h 20 :r 3)

  (display :assy (model-ref :assembly))

  (with-params (:w 80 :h 30)
    (def :br (model-ref :bracket)))
  (show :br)

  (fit-view)
  ```
]

#colbreak()

= View Controls
#concept-block[
  `set-view(orientation)`\
  `current-view()`\
  `fit-view()`\
  `set-view-aa(enable)`\

  #inline("Toggles")\
  `show-grid(&optional show)`\
  `toggle-grid()`\
  `show-axis(&optional show)`\
  `toggle-axis()`\
  `show-viewcube(&optional show)`\
  `toggle-viewcube()`\
  `show-viewcube-axes(&optional show)`\
  `toggle-viewcube-axes()`\

  #inline("Orientation")\
  `:top` `:bottom` `:front` `:back`\
  `:left` `:right` `:iso`\
]

= Dock Panels
#concept-block[
  `show-repl(&optional show)`\
  `toggle-repl()`\
  `show-scene-tree(&optional show)`\
  `toggle-scene-tree()`\
]

= Theme
#concept-block[
  `apply-theme(mode, ..options)`\
  `theme-dark(&optional accent)`\
  `theme-light(&optional accent)`\
  `theme-auto(&optional accent)`\
  `set-accent(color-hex)`\
  `set-font-size(size)`\
]

= File I/O
#concept-block[
  `write-step(shape, filename)`\
  `read-step(filename)`\
  `write-stl(shape, filename, ..options)`\
  `read-stl(filename)`\
  `write-dag-models-to-step(path)`\
  `read-step-into-dag(path)`\
  `help()`\
]

= Threading Macros
#concept-block[
  `->>` (thread-last) inserts result at end:\
  `(->> (make-box 10 10 10) (display :box))`\

  `as->` lets you place var explicitly:\
  `(as-> (make-box 10 10 10) v (display :box v))`\

  `->` inserts result at start:\
  `(-> (make-box 10 20 30) (translate 5 0 0))`\
]

= Introspection
#concept-block[
  `doc(name)`\
  `browse(pattern, ..options)`\
]
Prints docstring & arglist for any symbol. Searches API symbols by substring.

= REPL & Import
#concept-block[
  `cancel-import()`\
  `replay-speed(ms)`\
  `result-export(flag)`\
  `export-repl-history(path)`\
  `set-repl-history-key(modifier)`\
  `set-repl-submit-key(modifier)`
]
