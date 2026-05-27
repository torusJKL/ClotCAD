## Why

AI coding agents lack a structured reference for interacting with ClotCAD via `slyc`. Without it, they waste time probing APIs, miss silent errors, and can't reliably navigate the CAD workflow. A SKILL.md file provides the task-specific context agents need to be productive immediately.

## What Changes

- Create `docs/SKILL.md` covering:
  - Connecting to ClotCAD via `slyc --package CLOTCAD-USER`
  - Headless startup with `ClotCAD.AppImage --slynk`
  - Core CAD workflow for visionless agents (create, display, inspect, export)
  - Introspection via `doc`, `browse`, `help`
  - Querying subshapes for geometry inspection without vision
  - Available export formats (STEP, STL)
  - Error handling: silent errors, `*debugger-invocation-count*`, `show-errors`
  - `browse` categories and how to explore by category or substring search
  - Only visible objects are exported

## Capabilities

### New Capabilities

- `clotcad-agent-skill`: Skill definition file teaching AI agents how to interact with ClotCAD via slyc, covering lifecycle, geometry operations, introspection, export, and error handling

### Modified Capabilities

None — this is a new standalone file that doesn't change existing specs.

## Impact

- **New file**: `docs/SKILL.md` — example SKILL.md that users copy to `.agents/skills/clotcad/SKILL.md` in their projects
- **No API changes**: All functions referenced already exist in the codebase
- **No dependency changes**
