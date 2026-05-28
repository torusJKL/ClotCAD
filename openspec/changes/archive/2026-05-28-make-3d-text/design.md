## Context

Text creation in ClotCAD currently requires manual font loading, plane computation, and rotation chains:

```lisp
(let* ((font (make-brep-font-from-name "Cousine" 10 :aspect :regular))
       (text (make-text-shape-3d font "ClotCAD" 5 :h-align :center))
       (on-xz (rotate text 1 0 0 -90))
       (flip-y (rotate on-xz 0 1 0 180)))
  (display :clotcad-text (rotate flip-y 0 0 1 180)))
```

Recent cl-occt fixes (extrusion follows `:normal`, `:x-direction` parameter) eliminated the workarounds but didn't add convenience. The frame system (`make-frame-on-face`) already exists for arbitrary surface orientation. This design connects those pieces into a single user-facing function.

## Goals / Non-Goals

**Goals:**
- One-call 3D text creation with sensible defaults
- Support three plane placement modes: keyword planes, face geometry, explicit frames
- Automatic font fallback when no font is specified
- Return a standard `shape` object compatible with all existing ClotCAD operations (`display`, `def`, `write-step`, etc.)
- Update cheatsheet and api-reference docs

**Non-Goals:**
- Multi-line text formatting (existing `make-multi-line-text` covers this)
- Text on curved surfaces (tangent-plane approximation via `make-frame-on-face` is sufficient)
- Mirror/reflection transformation (composable via existing `rotate` and `translate`)
- Interactive text editing or AIS text labels (separate concern)

## Decisions

**1. Function location: new file `src/viewer/text.lisp` instead of adding to `ops.lisp`**

The function is distinct from existing ops (booleans, transforms, I/O) and has its own concerns (font resolution, plane mapping). A dedicated file keeps `ops.lisp` focused and makes future text-related additions natural. Exported from `clotcad` package, added to `src/viewer/package.lisp`.

**2. Plane resolution strategy: three-argument dispatch**

The `:plane` keyword accepts:
- `keyword` (`:xy`, `:xz`, `:yz`) → hardcoded normal + x-direction tables
- `shape` (face) → `make-frame-on-face` extracts frame, then use frame's X and Z as x-direction/normal
- `frame` → extract `frame-origin`, `frame-x-axis`, `frame-z-axis` directly

This avoids a type-dispatch tower by using `typecase` or `cond` with predicate checks.

Plane-to-orientation mapping:

| Keyword | Normal | x-direction | Up (Y = Z×X) |
|---------|--------|-------------|--------------|
| `:xy` | `(0,0,1)` | `(1,0,0)` | `(0,1,0)` |
| `:xz` (default) | `(0,1,0)` | `(1,0,0)` | `(0,0,1)` |
| `:yz` | `(1,0,0)` | `(0,1,0)` | `(0,0,1)` |

**3. Font fallback chain: hardcoded list**

Try each name in order: `"sans-serif"` → `"Arial"` → `"DejaVu Sans"` → `"Liberation Sans"` → `"FreeSans"`. If all fail, signal an error with a message listing available fonts (obtained via `list-available-fonts`). This is deterministic, avoids runtime font DB enumeration on every call, and covers Linux, macOS, and Windows common font sets.

**4. Alignment defaults: `:center` for both h-align and v-align**

Unlike `make-text-shape` which defaults to `:left`/`:bottom`, text labels are most commonly centered on a point. The override is trivially available via keyword.

## Risks / Trade-offs

- **[Font fallback may fail on minimal systems]** → Error message calls `list-available-fonts` and prints available names so the user can choose one.
- **[Non-planar face placement is approximate]** → `make-frame-on-face` produces a tangent plane at the face's UV midpoint. For highly curved surfaces, text may not follow the surface closely. Document as a known limitation.
- **[Plane keyword set is limited to three]** → Users who need arbitrary orientations can pass a `frame` instance (built via `make-frame-on-plane` with any normal/up).
