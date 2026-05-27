## ADDED Requirements

### Requirement: Agent connects to ClotCAD via slyc

The SKILL.md SHALL instruct AI agents to use `slyc --package CLOTCAD-USER --port 4005` for all interactions with a running ClotCAD instance. It SHALL document how to start ClotCAD headlessly with `ClotCAD.AppImage --slynk`.

#### Scenario: Agent connects and evaluates a form
- **WHEN** the agent runs `slyc --package CLOTCAD-USER --port 4005 "(+ 1 2)"`
- **THEN** the agent receives the result `3` with exit code 0

#### Scenario: Agent starts headless session
- **WHEN** the agent runs `ClotCAD.AppImage --slynk`
- **THEN** ClotCAD starts with Slynk server on port 4005, ready for slyc connections

### Requirement: Agent can create, display, and manage shapes

The SKILL.md SHALL document how to create shape primitives (`make-box`, `make-cylinder`, `make-sphere`, `make-cone`, `make-torus`), display them with `display`, and manage visibility with `show`, `hide`, `toggle`, `clear-all`.

#### Scenario: Agent creates a box and displays it
- **WHEN** the agent runs `slyc --package CLOTCAD-USER '(display :my-box (make-box 10 20 30))'`
- **THEN** a box shape is registered and visible in the 3D view

#### Scenario: Agent hides a displayed shape
- **WHEN** the agent runs `slyc --package CLOTCAD-USER '(hide :my-box)'`
- **THEN** the shape named `:my-box` is hidden from the 3D view

### Requirement: Agent inspects geometry without vision

The SKILL.md SHALL document how agents use subshape queries (`query-shape`, `top-face`, `bottom-face`, `longest-edge`, `shortest-edge`, `largest-face`, `smallest-face`) and predicate factories (`face-p`, `edge-p`, `vertex-p`, `normal-along`, `surface-type`, `curve-type`) to inspect geometry programmatically.

#### Scenario: Agent finds the top face of a box
- **WHEN** the agent runs `(top-face :my-box)`
- **THEN** the agent receives the top-most planar face shape object

#### Scenario: Agent queries faces by normal direction
- **WHEN** the agent runs `(query-shape :my-box :where (list (face-p) (normal-along 0 0 1)))`
- **THEN** the agent receives a list of face shapes whose normal points in +Z direction

### Requirement: Agent performs boolean and transform operations

The SKILL.md SHALL document `cut`, `fuse`, `common`, `section`, `translate`, `rotate`, `make-prism`, `make-revol`, `make-compound`, and `make-part`.

#### Scenario: Agent performs a boolean cut
- **WHEN** the agent runs `(cut (make-box 10 10 10) (make-sphere 5))`
- **THEN** the agent receives a new shape representing the box with the sphere subtracted

### Requirement: Agent exports shapes to STEP and STL

The SKILL.md SHALL document `write-step` and `write-stl` for per-shape export. It SHALL document that only visible shapes are included when exporting via File > Export (internal `export-all-step`/`export-all-stl`), but per-shape `write-step`/`write-stl` work on any shape.

#### Scenario: Agent exports a shape to STEP
- **WHEN** the agent runs `(write-step :my-box "/tmp/box.step")`
- **THEN** a STEP file is written to `/tmp/box.step`

#### Scenario: Agent exports a shape to STL with custom deflection
- **WHEN** the agent runs `(write-stl :my-box "/tmp/box.stl" :deflection 0.01)`
- **THEN** an STL file is written to `/tmp/box.stl` with fine tessellation

### Requirement: Agent detects and recovers from silent errors

The SKILL.md SHALL document the global debugger hook's silent-catch behavior, `*debugger-invocation-count*` for quick error detection, `show-errors` to display caught errors, `abort-all-threads` for recovery, and the error-checking agent pattern.

#### Scenario: Agent checks for silent errors after an operation
- **WHEN** the agent sets `*debugger-invocation-count*` to 0, performs an operation, then checks `*debugger-invocation-count*`
- **THEN** if the count is non-zero, the agent calls `(show-errors 5)` to display caught errors

### Requirement: Agent discovers API surface via introspection

The SKILL.md SHALL document `doc`, `browse`, and `help`. It SHALL describe how `browse` works: no-args for category tree, keyword for category detail, string for substring search. It SHALL instruct agents to use `doc` and `browse` as the primary discovery mechanism rather than relying on the skill being exhaustive.

#### Scenario: Agent browses primitives category
- **WHEN** the agent runs `(browse :primitives)`
- **THEN** the agent receives a detailed listing of all primitive creation functions with arglists and docstrings

#### Scenario: Agent looks up documentation for a function
- **WHEN** the agent runs `(doc make-box)`
- **THEN** the agent receives the package-qualified name, argument list, and docstring for `make-box`
