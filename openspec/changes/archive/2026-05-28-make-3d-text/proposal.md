## Why

Creating 3D text labels in ClotCAD currently requires manually loading fonts, computing plane orientations, and chaining multiple rotations. This is tedious and error-prone for a common operation — labeling parts, adding logos, annotations, and signage in 3D models. A single convenience function should handle font resolution, plane placement, and extrusion in one call.

This builds on recent cl-occt fixes: `make-text-shape-3d` now extrudes along the given `:normal` (not always global Z), and `:x-direction` was added for explicit control over text baseline orientation. The missing piece is a user-friendly wrapper in ClotCAD that ties these together with sensible defaults.

## What Changes

- **New function `make-3d-text`** in ClotCAD's `clotcad` package — a one-call 3D text label factory
  - `(make-3d-text string &key font size thickness h-align v-align plane)`
  - `:font` — font name string; default chain: `"sans-serif"` → `"Arial"` → `"DejaVu Sans"` → `"Liberation Sans"` → `"FreeSans"`
  - `:plane` — accepts `:xy`, `:xz` (default), `:yz`, a `face` shape, or a `frame` instance
  - Returns a `shape` ready for `display`, `def`, `write-step`, etc.
- **Updated cheatsheet** — add `make-3d-text` entry under a new "3D Text" section
- **Updated api-reference docs** — document `make-3d-text` with examples

No breaking changes. All existing APIs remain unchanged.

## Capabilities

### New Capabilities
- `make-3d-text`: Convenience function for creating extruded 3D text labels with automatic font resolution, plane orientation keywords, and face/frame-based placement

### Modified Capabilities
- `<existing-name>`: <what requirement is changing>

## Impact

- **Code**: New function in `src/viewer/ops.lisp` (or new `src/viewer/text.lisp`). Adds ~60-80 LOC.
- **Dependencies**: None beyond existing cl-occt text API and frame system
- **Documentation**: Cheatsheet update, api-reference addition
