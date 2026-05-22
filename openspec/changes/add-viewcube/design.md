## Context

The viewer has a 3D viewport with camera orbit/pan/zoom via AIS_ViewController, an AIS_Trihedron axis helper (lower-left), and a rectangular grid. Visibility of axis and grid is toggleable from the View menu and via Lisp functions (`show-axis`, `toggle-grid`, etc.). Theming uses a QSS template with {{token}} substitution generated from Lisp palette alists.

AIS_ViewCube is part of OCCT TKV3d (already linked). It provides built-in click handling for camera orientation with smooth animation, and supports transform persistence for corner display, the same pattern used by the existing AIS_Trihedron.

## Goals / Non-Goals

**Goals:**
- AIS_ViewCube displayed in the top-right corner, persisting across camera movements
- View menu checkbox to toggle ViewCube visibility (checked by default)
- Click-to-orient: clicking faces, edges, or vertices smoothly animates the camera
- Lisp `set-view` function accepting orientation keywords (:top, :bottom, :front, :back, :left, :right) with smooth animation
- Lisp `current-view` function returning the current orientation keyword
- Lisp `show-viewcube` / `toggle-viewcube` functions matching the grid/axis API
- Bidirectional sync: ViewCube clicks fire a Lisp callback updating `*current-view*`; Lisp `set-view` updates both camera and ViewCube
- ViewCube theming via the existing palette system (colors, text color, transparency, size)

**Non-Goals:**
- Custom ViewCube geometry or labels beyond what AIS_ViewCube provides
- Multiple simultaneous ViewCubes
- ViewCube in separate overlay window (must be in-viewport with transform persistence)
- Animation speed customization (uses AIS_ViewCube defaults)
- Keyboard shortcuts for view orientations

## Decisions

### 1. ViewCube creation: Eager in ViewerState, lazy display

**Decision:** Create the `AIS_ViewCube` in `viewer_create` (after context exists) and display it immediately with `ToAutoStartAnimation` enabled. Visibility control uses `Display`/`Erase` like the axis trihedron.

**Rationale:** The ViewCube is always needed; eager creation at startup avoids null checks and late-initialization complexity. The display/erase pattern matches the existing axis trihedron exactly. `ToAutoStartAnimation` (default `true`) makes click-to-orient work with zero custom code.

### 2. Visibility toggle: Grid/axis pattern

**Decision:** Add `viewer_show_viewcube` / `viewer_is_viewcube_visible` C API functions following the exact same signature and behavior as `viewer_show_axis` / `viewer_is_axis_visible`.

**Rationale:** Consistency with the existing pattern reduces cognitive load for both C++ maintainers and Lisp callers. The ViewCube action in ViewerWindow follows the same checkable pattern as `axisAction` and `gridAction`.

### 3. View control: Direct OCCT call + keyword mapping

**Decision:** `viewer_set_view` takes an `int` enum value matching `V3d_TypeOfOrientation` and calls `V3d_View::SetProj()`. The Lisp `set-view` function maps keywords (:top, :bottom, etc.) to integer values.

**Rationale:** `V3d_View::SetProj()` is a lightweight call that sets the camera direction. The ViewCube automatically updates its highlight to reflect the current view (built-in behavior). No animation loop needed — `SetProj` is instant. For animation, the ViewCube's own click handler provides it. The Lisp keyword → int mapping is clean and type-safe.

### 4. Bidirectional sync: Callback for ViewCube clicks, direct update for Lisp

**Decision:**
- **ViewCube → Lisp**: Override `onAnimationFinished()` on the ViewCube to read `V3d_View::Proj()`, convert to `V3d_TypeOfOrientation`, and call a registered `viewcube_fn` callback. Lisp side stores result in `*current-view*`.
- **Lisp → ViewCube**: `viewer_set_view` calls `V3d_View::SetProj()` directly. The ViewCube highlight updates automatically by OCCT's internal camera → orientation mapping.

**Rationale:** `onAnimationFinished()` is called after any ViewCube-initiated camera animation completes. This is the natural hook to notify Lisp. For Lisp-initiated calls, `SetProj` is synchronous and immediate — no animation to wait for. The ViewCube's built-in camera-orientation tracking means no explicit sync call is needed.

### 5. Theming: Palette extension + Lisp apply function

**Decision:** Add `:viewcube-color`, `:viewcube-text-color`, `:viewcube-inner-color`, and `:viewcube-transparency` to both `%dark-palette` and `%light-palette`. Add `%apply-viewcube-colors` function in `theme.lisp` called from `apply-theme`. On the C++ side, add `viewer_set_viewcube_color`, `viewer_set_viewcube_text_color`, `viewer_set_viewcube_inner_color`, `viewer_set_viewcube_transparency`, and `viewer_set_viewcube_size`.

**Rationale:** Matches the existing pattern where `%apply-axis-colors` reads palette values and calls C++ setters. Palette reuse ensures consistent light/dark switching without extra effort.

### 6. Thread model: Direct CFFI call from worker thread

**Decision:** `viewer_show_viewcube`, `viewer_set_view`, and `viewer_get_view_orientation` are called from the Lisp worker thread via CFFI, same as `viewer_show_grid` and `viewer_show_axis`.

**Rationale:** These are lightweight OCCT state changes (Display/Erase, SetProj) that don't involve Qt widget manipulation. No queue/postEvent needed. The ViewCube click (main thread) fires the orientation callback synchronously on the main thread — Lisp state update is trivial.

## Risks / Trade-offs

| Risk | Impact | Mitigation |
|------|--------|------------|
| ViewCube click during Lisp `set-view` call (race) | Stale `*current-view*` | `*current-view*` is only a hint; actual camera state is authoritative. Acceptable race. |
| `onAnimationFinished()` fires on main thread — Lisp callback must not block | Qt event loop stuck | Callback only sets a global variable, no heavy computation. Document that callback must be lightweight. |
| ViewCube overlaps with shapes when displayed in top-right | Visual occlusion | AIS_ViewCube with transform persistence renders on top of scene content. This is standard CAD behavior. |
