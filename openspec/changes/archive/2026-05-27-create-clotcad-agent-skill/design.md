## Context

ClotCAD exposes a rich Lisp API for 3D CAD modeling via `slyc --package CLOTCAD-USER` (port 4005). AI agents that lack vision need a structured reference to navigate this API effectively — they can't see the 3D viewport, so they rely on programmatic feedback (query results, error counts, introspection) instead.

The codebase already has all the building blocks:
- Shape primitives (`make-box`, `make-cylinder`, etc.) in `lib/cl-occt/src/core/primitives.lisp`
- Boolean ops (`cut`, `fuse`, `common`, `section`) in `src/viewer/ops.lisp`
- Subshape queries (`query-shape`, `top-face`, `normal-along`, etc.) in `src/viewer/query.lisp`
- Introspection (`doc`, `browse`, `help`) in `src/viewer/introspect.lisp` and `src/model/api.lisp`
- Export formats in `lib/cl-occt/src/core/io.lisp` (STEP, STL, OBJ, IGES, VRML, glTF, PLY)
- Error handling (`*debugger-invocation-count*`, `show-errors`, global debugger hook) in `src/viewer/repl.lisp`
- Named subshapes (`name-subshape`, `face-ref`, etc.) in `src/viewer/naming.lisp`

No new code is needed — the SKILL.md just documents what already exists.

## Goals / Non-Goals

**Goals:**
- Create `docs/SKILL.md` as an example SKILL.md for users to copy to `.agents/skills/clotcad/SKILL.md` in their projects
- Cover: connecting, lifecycle, shape creation, display/visibility, subshape queries, boolean ops, transformations, export (STEP/STL only), introspection, error handling, view control
- Teach the agent agent patterns: error-checking pattern, subshape-query pattern, display-and-verify pattern
- Reference only existing API surface — do not design new capabilities

**Non-Goals:**
- No image/screenshot export (deferred)
- No new C++ CFFI bindings
- No changes to existing code
- No comprehensive listing of every function (agent should use `doc`/`browse` for details)

## Decisions

1. **Reference, not tutorial**: SKILL.md is structured as a reference organized by task category, not a linear tutorial. Agents skip to relevant sections by intent.

2. **Agent patterns embedded**: Include reusable instruction blocks (e.g., error-checking before/after operations) that agents can follow verbatim.

3. **Five sections**:
   - **Connecting** — slyc usage + headless `ClotCAD.AppImage --slynk`
   - **Core CAD Workflow** — create → display → inspect → modify → export
   - **Inspecting Geometry Without Vision** — subshape queries, named subshapes, measurements
   - **Error Handling** — silent errors, stuck threads, recovery
   - **Finding What You Need** — doc, browse, help, category exploration

4. **Export note**: Only visible objects are exported via `export-all-step`/`export-all-stl`. Per-shape `write-step`/`write-stl` work on any shape regardless of visibility.

## Risks / Trade-offs

- **Staleness risk**: SKILL.md could drift from the actual API as the codebase evolves. Mitigated by keeping it high-level and directing agents to `doc`/`browse` for detail — the skill teaches *how to explore*, not *everything there is*.
- **Missing features won't be obvious**: Agents following the SKILL.md won't try capabilities that aren't mentioned even if they exist. Mitigated by including `browse` instructions so agents discover anything we didn't list.
- **Headless startup unknown**: `ClotCAD.AppImage --slynk` is mentioned in `scripts/run.sh` but the exact entry point needs verification.
