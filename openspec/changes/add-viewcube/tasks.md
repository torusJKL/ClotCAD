## 1. C++: ViewerState extension + ViewCube creation

- [x] 1.1 Add `#include <AIS_ViewCube.hxx>` to `occt_viewer.cpp`
- [x] 1.2 Add `Handle(AIS_ViewCube) viewCube;` field to `ViewerState` struct in `viewer_state.h`
- [x] 1.3 Add `viewcube_fn viewcube_callback = nullptr;` callback field to `ViewerState` struct
- [x] 1.4 Create `AIS_ViewCube` in `viewer_create()` after context exists — set `Graphic3d_TMF_TriedronPers` at `Aspect_TOTP_RIGHT_UPPER` with offset `(100, 100)`
- [x] 1.5 Display the ViewCube with `context->Display()` and `context->Deactivate()` (prevent selection interference)
- [x] 1.6 Override `onAnimationFinished()` on the ViewCube to read `V3d_View::Proj()`, convert to `V3d_TypeOfOrientation`, and fire the registered callback

## 2. C++: ViewCube visibility toggle C API

- [x] 2.1 Add `viewer_show_viewcube` to `occt_viewer.h` — signature: `void viewer_show_viewcube(occt_viewer vwr, int show)`
- [x] 2.2 Implement `viewer_show_viewcube` — use `Display`/`Erase` on the ViewCube handle, sync menu action checked state, call `viewer_redraw`
- [x] 2.3 Add `viewer_is_viewcube_visible` — signature: `int viewer_is_viewcube_visible(occt_viewer vwr)`
- [x] 2.4 Implement `viewer_is_viewcube_visible` — read menu action checked state

## 3. C++: Programmatic view set/get C API

- [x] 3.1 Add `viewer_set_view` to `occt_viewer.h` — signature: `void viewer_set_view(occt_viewer vwr, int orientation)`
- [x] 3.2 Implement `viewer_set_view` — call `V3d_View::SetProj((V3d_TypeOfOrientation)orientation)` then `viewer_redraw`
- [x] 3.3 Add `viewer_get_view_orientation` — signature: `int viewer_get_view_orientation(occt_viewer vwr)`
- [x] 3.4 Implement `viewer_get_view_orientation` — call `V3d_View::Proj()` and return the int value

## 4. C++: ViewCube orientation change callback

- [x] 4.1 Add `viewcube_fn` typedef to `occt_viewer.h` — `typedef void (*viewcube_fn)(int orientation);`
- [x] 4.2 Add `viewer_set_viewcube_callback` — signature: `void viewer_set_viewcube_callback(occt_viewer vwr, viewcube_fn fn);`
- [x] 4.3 Implement — store callback in `ViewerState`, invoke from `onAnimationFinished()` override

## 5. C++: ViewCube theming C API

- [x] 5.1 Add `viewer_set_viewcube_color` — signature: `void viewer_set_viewcube_color(occt_viewer vwr, double r, double g, double b)`
- [x] 5.2 Implement — call `viewCube->SetBoxColor(Quantity_Color(r, g, b, Quantity_TOC_RGB))`
- [x] 5.3 Add `viewer_set_viewcube_text_color` — signature: `void viewer_set_viewcube_text_color(occt_viewer vwr, double r, double g, double b)`
- [x] 5.4 Implement — call `viewCube->SetTextColor(Quantity_Color(r, g, b, Quantity_TOC_RGB))`
- [x] 5.5 Add `viewer_set_viewcube_inner_color` — signature: `void viewer_set_viewcube_inner_color(occt_viewer vwr, double r, double g, double b)`
- [x] 5.6 Implement — call `viewCube->SetInnerColor(Quantity_Color(r, g, b, Quantity_TOC_RGB))`
- [x] 5.7 Add `viewer_set_viewcube_transparency` — signature: `void viewer_set_viewcube_transparency(occt_viewer vwr, double t)`
- [x] 5.8 Implement — call `viewCube->SetTransparency(t)`
- [x] 5.9 Add `viewer_set_viewcube_size` — signature: `void viewer_set_viewcube_size(occt_viewer vwr, double size)`
- [x] 5.10 Implement — call `viewCube->SetSize(size)`

## 6. C++: Menu action wiring

- [x] 6.1 Add `myViewCubeAction` QAction* to `ViewerWindow` in `viewer_window.h` with getter
- [x] 6.2 Add "ViewCube" checkable action to View menu in `viewer_window.cpp` `setupMenus()`
- [x] 6.3 Wire menu toggled signal in `viewer_create()` — same pattern as axisAction/gridAction

## 7. Lisp: CFFI bindings

- [x] 7.1 Add `%viewer-show-viewcube` binding — `(defcfun ... "viewer_show_viewcube")`
- [x] 7.2 Add `%viewer-is-viewcube-visible` binding — `(defcfun ... "viewer_is_viewcube_visible")`
- [x] 7.3 Add `%viewer-set-view` binding — `(defcfun ... "viewer_set_view")`
- [x] 7.4 Add `%viewer-get-view-orientation` binding — `(defcfun ... "viewer_get_view_orientation")`
- [x] 7.5 Add `%viewer-set-viewcube-callback` binding — `(defcfun ... "viewer_set_viewcube_callback")`
- [x] 7.6 Add `%viewer-set-viewcube-color` binding — `(defcfun ... "viewer_set_viewcube_color")`
- [x] 7.7 Add `%viewer-set-viewcube-text-color` binding — `(defcfun ... "viewer_set_viewcube_text_color")`
- [x] 7.8 Add `%viewer-set-viewcube-inner-color` binding — `(defcfun ... "viewer_set_viewcube_inner_color")`
- [x] 7.9 Add `%viewer-set-viewcube-transparency` binding — `(defcfun ... "viewer_set_viewcube_transparency")`
- [x] 7.10 Add `%viewer-set-viewcube-size` binding — `(defcfun ... "viewer_set_viewcube_size")`

## 8. Lisp: High-level functions and state

- [x] 8.1 Add `*current-view*` state variable (initially NIL) to `ui.lisp`
- [x] 8.2 Add `*viewcube-visible*` state variable (initially T) to `ui.lisp`
- [x] 8.3 Implement `show-viewcube` — call `%viewer-show-viewcube`, set `*viewcube-visible*`
- [x] 8.4 Implement `toggle-viewcube` — invert `*viewcube-visible*`, call `show-viewcube`
- [x] 8.5 Implement `view-keyword->int` helper — map :top→V3d_Xpos, :bottom→V3d_Xneg, :front→V3d_Ypos, :back→V3d_Yneg, :left→V3d_Zpos, :right→V3d_Zneg, :iso→V3d_XposYposZpos
- [x] 8.6 Implement `view-int->keyword` helper — reverse mapping
- [x] 8.7 Implement `set-view` — convert keyword to int, call `%viewer-set-view`, update `*current-view*`
- [x] 8.8 Implement `current-view` — call `%viewer-get-view-orientation`, convert int to keyword

## 9. Lisp: Callback registration

- [x] 9.1 Define `cffi:defcallback %on-viewcube-orientation` — convert int to keyword, set `*current-view*`
- [x] 9.2 Register the callback in `register-viewer-callbacks` in `repl.lisp` — call `%viewer-set-viewcube-callback`
- [x] 9.3 Add `register-viewcube-callback` function (safe to call multiple times)

## 10. Lisp: Theme palette integration

- [x] 10.1 Add `:viewcube-color`, `:viewcube-text-color`, `:viewcube-inner-color`, `:viewcube-transparency` to `%dark-palette` in `theme.lisp`
- [x] 10.2 Add same keys to `%light-palette`
- [x] 10.3 Implement `%apply-viewcube-colors` — read palette values, call CFFI setters
- [x] 10.4 Call `%apply-viewcube-colors` from `apply-theme` after existing `%apply-axis-colors` call
- [x] 10.5 Export new symbols in `package.lisp`

## 11. Unit tests

- [x] 11.1 Add `%viewer-show-viewcube`, `%viewer-is-viewcube-visible`, `%viewer-set-view`, `%viewer-get-view-orientation`, `%viewer-set-viewcube-callback`, and theming CFFI functions to the `with-mocked-viewer` mock list in test package
- [x] 11.2 Add test for `show-viewcube` / `toggle-viewcube` — verify `*viewcube-visible*` state transitions
- [x] 11.3 Add test for `set-view` with each orientation keyword — verify `*current-view*` is set correctly
- [x] 11.4 Add test for `current-view` after `set-view` — verify round-trip consistency
- [x] 11.5 Add test for viewcube orientation callback — simulate callback invocation, verify `*current-view*` update
- [x] 11.6 Add test for theme palette — verify `%apply-viewcube-colors` is called during `apply-theme`

## 12. README update

- [x] 12.1 Add ViewCube to the Layout diagram in README.md
- [x] 12.2 Add `(show-viewcube nil)`, `(toggle-viewcube)`, `(set-view :top)`, `(current-view)` to the Usage examples
- [x] 12.3 Add "ViewCube" row to the Interface table

## Task dependencies

```
1 (ViewerState + creation) ──→ 2 (visibility toggle)
1 ──→ 3 (view set/get)
1 ──→ 4 (orientation callback)
1 ──→ 5 (theming API)
2 + ViewerWindow ──→ 6 (menu wiring)
7 (CFFI bindings) ──→ 8 (high-level functions)
7 + 4 ──→ 9 (callback registration)
7 + 5 ──→ 10 (theme integration)
8 + 9 + 10 ──→ 11 (tests)
12 (README) — independent
```
