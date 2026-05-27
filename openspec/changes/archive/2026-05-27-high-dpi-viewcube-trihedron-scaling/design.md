## Context

The ClotCAD 3D viewer uses OCCT's `AIS_ViewCube` (top-right corner orientation widget) and `AIS_Trihedron` (lower-left axis indicator). Both are created with hardcoded pixel sizes and font heights — the ViewCube defaults to `SetSize(70)` with font height `11.2` (= `70 × 0.16`), and the trihedron defaults to `SetSize(50)`.

OCCT correctly reports the device pixel ratio (DPR) via `Aspect_NeutralWindow::DevicePixelRatio()` for framebuffer sizing and mouse coordinate conversion, but does **not** automatically scale geometry sizes or font heights for transform-persistent objects. On a 4K display at 2× DPR, the ViewCube text renders at 11.2 device pixels — physically ~1.7mm, unreadable.

The C++ rendering layer (`wrap/`) already passes `devicePixelRatioF()` when initializing OCCT's window. The gap is exclusively in the hardcoded size/position values for the ViewCube and trihedron.

## Goals / Non-Goals

**Goals:**
- ViewCube and trihedron geometry, font sizes, and corner offsets scale by device pixel ratio automatically at startup
- Users can override font heights/sizes at runtime for theming via `set-viewcube-font-height` and `set-trihedron-font-size`
- Theme palettes include `:viewcube-font-height` and `:trihedron-font-size` keys
- All C++ font setters are DPR-aware — callers pass logical pixels, C++ multiplies by DPR
- `viewer_get_device_pixel_ratio` is exposed so Lisp can query DPR for other scaling needs

**Non-Goals:**
- Not scaling the grid or other UI elements (separate concern)
- Not adding a general `set-trihedron-size` function (the trihedron's arrow geometry changes proportionally with the fonts, and the default `50.0 * dpr` handles the common case)
- Not making existing `viewer_set_viewcube_size` or corner-offset setters DPR-aware (they're internal; Lisp calls them with DPR-scaled values instead)

## Decisions

### Decision 1: DPR multiplication in C++ setters, not Lisp
- **Chosen**: Each new font setter internally multiplies by `widget->devicePixelRatioF()`.
- **Rationale**: Callers (both startup code and power users) should think in logical pixels. A user who says `(set-viewcube-font-height 20)` wants 20px visual height regardless of display. If DPR were the caller's responsibility, every call site would need `(set-viewcube-font-height (* 20 (get-device-pixel-ratio)))` — error-prone and ugly.
- **Alternatives considered**:
  - Lisp-side DPR multiplication: rejected because it forces all callers (including theme system and REPL users) to know about DPR.
  - DPR-agnostic raw C++ setter + Lisp wrapper: redundant layer with no benefit.

### Decision 2: Scale at creation time in C++ AND at init time in Lisp
- **Chosen**: `viewer_create()` scales sizes/offsets/fonts by DPR at ViewCube construction. `viewer_show_axis()` scales trihedron at construction. Additionally, `initialize-viewer` in Lisp re-applies scaled values.
- **Rationale**: The C++ creation-time scaling gives correct defaults immediately — the ViewCube is right-sized from frame 1. The Lisp init-time call ensures that if the theme system later re-applies palette values, the DPR factor is still respected (the palette stores logical pixel values, and setter multiplies by DPR).
- **Risk**: Double-application — but it's idempotent (16 × 2 = 32, set to 32; then 16 × 2 = 32 again).

### Decision 3: `viewer_set_trihedron_font_size` sets all three axis labels uniformly
- **Chosen**: A single `double size` parameter applied to X, Y, and Z axis text aspects.
- **Rationale**: No use case for per-axis font sizing. Uniform sizing matches the ViewCube's `SetFontHeight` API and is simpler.
- **Alternatives considered**: Per-axis font size (rejected as over-engineering).

### Decision 4: Palette values stored as strings, parsed with `read-from-string`
- **Chosen**: Follows the existing pattern for `:viewcube-transparency`.
- **Rationale**: Consistency with existing theme system. The palette alist uses string values throughout; numeric values are `read-from-string`'d at apply time.

## Risks / Trade-offs

- **OCCT version coupling**: If a future OCCT 8.x release adds built-in DPR scaling for `AIS_ViewCube`, these manual scalings would double-apply. Mitigation: version-gate new OCCT versions behind `Standard_Version.hxx` when/if that happens.
- **Trihedron `SetToUpdate` not followed by `Redisplay`**: The `viewer_set_trihedron_font_size` setter calls `SetToUpdate()` but doesn't force a redisplay. If the trihedron was created by `viewer_show_axis` with `show=0` (hidden), the presentation won't be regenerated until the trihedron is displayed. This is acceptable because font size only matters when visible.
- **Temporary pixel mismatch during startup**: Between `viewer_create` (which sets DPR-scaled defaults in C++) and `initialize-viewer` (which re-applies in Lisp), the values are correct. No window is visible yet because `initialize-viewer` runs before `viewer_run`.
