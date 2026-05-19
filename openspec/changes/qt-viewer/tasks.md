## 1. GL wrapping helpers (from occt-samples-qt)

- [x] 1.1 Create `wrap/OcctQtTools.h` — Qt↔OCCT conversions, input event mapping, surface format setup
- [x] 1.2 Create `wrap/OcctQtTools.cpp` — implementation of platform setup, mouse/kb event conversion
- [x] 1.3 Create `wrap/OcctGlTools.h` — GL context wrapping, FBO management, GL state reset declarations
- [x] 1.4 Create `wrap/OcctGlTools.cpp` — `InitializeGlWindow()`, `InitializeGlFbo()`, `ResetGlStateBeforeOcct()`, `ResetGlStateAfterOcct()`
- [x] 1.5 Verify: Both pairs compile with `g++ -c -std=c++17 -I.local/include/opencascade $(pkg-config --cflags Qt6Widgets Qt6OpenGLWidgets)`

## 2. ViewerWidget — 3D viewport (QOpenGLWidget + AIS_ViewController)

- [x] 2.1 Create `wrap/viewer_widget.h` — class inheriting QOpenGLWidget and AIS_ViewController
- [x] 2.2 Implement `initializeGL()` — create OcctNeutralWindow, OpenGl_GraphicDriver, V3d_Viewer, AIS_InteractiveContext, V3d_View, wrap via OcctGlTools
- [x] 2.3 Implement `paintGL()` — wrap Qt FBO via OcctGlTools, reset GL state, FlushViewEvents, reset GL state
- [x] 2.4 Implement `resizeGL()` — call `myView->MustBeResized()`
- [x] 2.5 Implement mouse input forwarding — `mousePressEvent`, `mouseReleaseEvent`, `mouseMoveEvent` → `AIS_ViewController::UpdateMouseButtons()` / `UpdateMousePosition()`
- [x] 2.6 Implement `wheelEvent` → `AIS_ViewController::UpdateScroll()`
- [x] 2.7 Implement `handleViewRedraw()` override — emit `updateView()` if animation frames pending
- [x] 2.8 Add AIS_Trihedron axis helper in `initializeGL()` — transform persistence, lower-left corner
- [x] 2.9 Activate rectangular grid on V3d_Viewer in `initializeGL()`
- [x] 2.10 Enable MSAA 4x in `ChangeRenderingParams()`

## 3. ViewerWindow — QMainWindow with menus and status bar

- [x] 3.1 Create `wrap/viewer_window.h` — QMainWindow subclass with ViewerWidget as central widget
- [x] 3.2 Create `wrap/viewer_window.cpp` — constructor, layout, close event handler
- [x] 3.3 Implement `setupMenus()` — File menu (Import STEP/STL, Export STEP/STL), View menu (REPL toggle, Scene Tree toggle, Axis toggle, Grid toggle)
- [x] 3.4 Add QStatusBar — shape count label + FPS label
- [x] 3.5 Dock panels created in setupPanels() — REPL (right), Scene Tree (left)
- [x] 3.6 Wire close event to call `QApplication::quit()`

## 4. occt_viewer — C API + ViewerState

- [x] 4.1 Create `wrap/occt_viewer.h` — extern "C" API: lifecycle, shapes, callbacks, grid/axis/AA
- [x] 4.2 Create `wrap/occt_viewer.cpp` — ViewerState, QApplication singleton, shape map, callbacks, wake receiver
- [x] 4.3 Implement `viewer_create()` — init QApp, create ViewerWindow, wire menus/dialogs
- [x] 4.4 Implement `viewer_show()` — show the window
- [x] 4.5 Implement `viewer_run()` — call QApplication::exec() (blocks main thread)
- [x] 4.6 Implement `viewer_quit()` — call QApplication::quit()
- [x] 4.7 Implement `viewer_post_event()` — QCoreApplication::postEvent() with WakeEvent
- [x] 4.8 Implement shape functions: `viewer_put/shape()`, `viewer_remove_shape()`, `viewer_clear()`, `viewer_fit_all()`
- [x] 4.9 Implement shape query functions
- [x] 4.10 Implement visibility functions
- [x] 4.11 Implement grid/axis functions
- [x] 4.12 Implement `viewer_set_antialiasing()`
- [x] 4.13 Add `viewer_set_drain_callback()` for Lisp queue draining

## 5. REPLPanel — Qt REPL dock widget

- [x] 5.1 Create `wrap/repl_panel.h` — REPLPanel class inheriting QDockWidget
- [x] 5.2 Create `wrap/repl_panel.cpp` — QPlainTextEdit output + QLineEdit input
- [x] 5.3 Implement input submission with eval callback
- [x] 5.4 Implement history navigation
- [x] 5.5 Implement `appendOutput()` with queued connection for thread safety
- [x] 5.6 Wire into ViewerWindow as right dock

## 6. SceneTreePanel — Qt scene tree dock widget

- [x] 6.1 Create `wrap/scene_tree_panel.h`
- [x] 6.2 Create `wrap/scene_tree_panel.cpp` — QTreeWidget with checkboxes
- [x] 6.3 Implement `addShape()`
- [x] 6.4 Implement `removeShape()`
- [x] 6.5 Implement `clearAll()`
- [x] 6.6 Wire checkbox toggles → context->Display/Erase
- [x] 6.7 Connect ViewerState → SceneTreePanel updates

## 7. File I/O — menu integration + QFileDialog

- [x] 7.1 Wire Import STEP with QFileDialog
- [x] 7.2 Wire Import STL with QFileDialog
- [x] 7.3 Wire Export STEP with QFileDialog
- [x] 7.4 Wire Export STL with QFileDialog

## 8. CMakeLists.txt — build system

- [x] 8.1 Create `CMakeLists.txt`
- [x] 8.2 CMAKE_AUTOMOC ON
- [x] 8.3 All wrap/ sources added
- [x] 8.4 Qt6 + OCCT libraries linked
- [x] 8.5 Install target
- [x] 8.6 Verify: `cmake --build build` produces libocctviewer.so

## 9. justfile + start.lisp — convenience scripts

- [x] 9.1 Create `justfile`
- [x] 9.2 Create `start.lisp`

## 10. Lisp bindings — package.lisp + bindings.lisp

- [x] 10.1 Rewrite `package.lisp`
- [x] 10.2 Rewrite `bindings.lisp`
- [x] 10.3 Update `queue.lisp` — `%viewer-wake` → `%viewer-post-event`, DAG bridge
- [ ] 10.4 Verify: Lisp can load the system and call `%viewer-create` without errors

## 11. Lisp lifecycle — threading and integration

- [x] 11.1 Rewrite `lifecycle.lisp`
- [x] 11.2 Implement `stop-viewer`
- [x] 11.3 Test end-to-end: viewer displays solid sphere and box via REPL `(display :s (make-sphere 20))`

## Task dependencies

```
1 (OcctQtTools, OcctGlTools) ──→ 2 (ViewerWidget)
2 ──→ 3 (ViewerWindow)
3 + 2 ──→ 4 (occt_viewer C API)
4 ──→ 5 (REPLPanel)
4 ──→ 6 (SceneTreePanel)
3 + 5 + 6 ──→ 7 (File I/O)
8 (CMakeLists.txt) ──→ 9 (justfile + start.lisp)
9 + 4 + 5 + 6 + 7 ──→ 10 (Lisp bindings)
10 ──→ 11 (Lisp lifecycle, end-to-end)
```
