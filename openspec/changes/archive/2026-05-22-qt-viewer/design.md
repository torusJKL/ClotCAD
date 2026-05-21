## Context

The existing GLFW+ImGui viewer on `main` is not functional. A clean Qt-based viewer is being built from scratch on the `qt-viewer` branch, sharing OCCT build artifacts (`.local/`) with the main branch. The viewer must integrate with cl-occt (Common Lisp OCCT bindings) and support cross-platform deployment (Linux, Windows, macOS).

## Goals / Non-Goals

**Goals:**
- Qt6 window with QOpenGLWidget 3D viewport rendering OCCT AIS presentations (TKV3d)
- AIS_ViewController for camera orbit/pan/zoom (replacing manual GLFW math)
- Native Qt widgets for all UI: menus, REPL panel, scene tree, status bar, file dialogs
- Cross-platform: Linux, Windows, macOS (single codebase, no platform #ifdef soup)
- Event-driven rendering (0% CPU idle when no events)
- Integration with Lisp: Qt REPL eval callback + thread-safe shape queue from Swank/SLIME
- AIS_Trihedron axis helper + rectangular grid
- Anti-aliased rendering (MSAA)
- Import/export STEP and STL

**Non-Goals:**
- Viewport overlays or heads-up displays (no ImGui)
- Animation/playback
- Full window management (Blender-style split/join)
- In-viewport object selection beyond what AIS_ViewController provides by default
- Standalone executable packaging (deferred)
- Unit tests (deferred — manual QA for now)

## Decisions

### 1. Threading: Qt on main thread, Swank on worker thread

**Decision:** QApplication::exec() runs on the main thread. Swank/SLIME server runs in a background thread.

**Rationale:** macOS requires all UI calls on the main thread. This architecture works on all three platforms. The worker thread handles REPL input and SLIME connections without blocking Qt. The Qt REPL's eval callback is synchronous (blocks Qt briefly for short expressions; for heavy work, use SLIME).

**Alternatives considered:**
- Qt on worker thread (GLFW current model) — fails on macOS
- Single-threaded with non-blocking stdin — complex, breaks terminal REPL ergonomics

### 2. UI toolkit: Native Qt widgets, no ImGui

**Decision:** All UI rendered with Qt widgets (QPlainTextEdit, QTreeWidget, QMenuBar, QStatusBar, QDockWidget, QFileDialog).

**Rationale:** Native text rendering (REPL), proper keyboard handling, accessibility, OS integration (native file dialogs), no mixed-toolkit complexity.

### 3. Camera control: AIS_ViewController

**Decision:** ViewerWidget inherits AIS_ViewController and forwards Qt mouse events to it.

**Rationale:** Eliminates ~70 lines of manual orbit/pan/zoom math. Provides built-in smooth inertia, progressive display, and view animation. Matches the occt-samples-qt reference pattern.

### 4. Window abstraction: OcctNeutralWindow (virtual window)

**Decision:** Use OcctNeutralWindow (from occt-samples-qt) instead of Xw_Window.

**Rationale:** Xw_Window is X11-specific and won't work on Windows/macOS. OcctNeutralWindow wraps any native window handle and is platform-neutral.

### 5. GL context: Qt owns it, OCCT wraps it

**Decision:** QOpenGLWidget creates and owns the GL context. OCCT wraps it in initializeGL() via OpenGl_Context::Init(). Qt's FBO is wrapped for OCCT rendering in paintGL().

**Rationale:** This is the established pattern from occt-samples-qt. Qt manages the GL context lifecycle, OCCT borrows it for rendering.

### 6. Build system: CMake

**Decision:** CMakeLists.txt with find_package(Qt6) for compilation, a justfile wrapper for convenience.

**Rationale:** CMake is the standard for Qt projects. Qt6's CMake integration is first-class. The justfile provides a familiar entry point matching the project convention.

### 7. C API: Minimal, stable interface

**Decision:** Keep the extern "C" interface pattern but remove all GLFW- and ImGui-specific functions. Add viewer_run/viewer_quit/viewer_post_event for Qt lifecycle.

**Rationale:** The C API is the ABI boundary between C++ (Qt/OCCT) and Lisp (CFFI). Keeping it clean and minimal makes the Lisp bindings straightforward.

## Architecture Diagram

```
┌───────────────────────────────────────────────────────────┐
│  Main Thread (Qt)               Worker Thread (Swank)     │
│  ┌───────────────────────────┐  ┌─────────────────────────┐│
│  │ QApplication::exec()      │  │ Swank :port 4005        ││
│  │                           │  │   └─ SLIME eval threads ││
│  │  ViewerWindow : QMainWindow                            ││
│  │   ├─ QMenuBar             │  │                         ││
│  │   │  File, View           │  │ SLIME → worker thread:  ││
│  │   ├─ ViewerWidget : QOpenGLWidget + AIS_ViewController ││
│  │   │  paintGL():           │  │  display() → push queue ││
│  │   │   ① Wrap Qt FBO       │  │  → QCoreApplication::  ││
│  │   │   ② Reset GL state    │  │    postEvent() (thread- ││
│  │   │   ③ FlushViewEvents   │  │    safe)                ││
│  │   │   ④ Reset GL state    │  │  → Qt drains → paintGL ││
│  │   ├─ REPLPanel (QDock)    │  │                         ││
│  │   │  QPlainTextEdit out   │  │ Ctrl-C from terminal:   ││
│  │   │  QLineEdit in → eval_cb│  │  → SBCL debugger       ││
│  │   └─ SceneTreePanel (Dock)│  │  → Qt main thread stuck ││
│  │      QTreeWidget + checks │  │  → abort → unfreeze     ││
│  │                           │  │                         ││
│  │  Wake path:               │  │                         ││
│  │  QEvent::User arrives →   │  │                         ││
│  │    drain queue → update() │  │                         ││
│  └───────────────────────────┘  └─────────────────────────┘│
│                                                             │
│  libocctviewer.so: Qt6 + OCCT TKV3d (AIS)                 │
└─────────────────────────────────────────────────────────────┘
```

## Communication Flows

### Lisp → Qt (shape changes from SLIME/terminal)
```
Worker thread: display(name, shape) → push to mutex queue → postEvent()
Main thread:   QEvent::User → drain queue → ViewerWidget::update()
               → paintGL() → OCCT Redraw
```

### Qt → Lisp (REPL eval)
```
Main thread:   Enter in QLineEdit → eval_callback(code, result, maxlen)
               → Lisp eval (synchronous, blocks Qt briefly)
               → result written to buffer → appended to QPlainTextEdit
```

### Recovery from stuck eval (infinite loop in Qt REPL)
```
Terminal: SIGINT → SBCL debugger on main thread (Qt frozen)
SLIME:    Still alive on worker thread → user can inspect/abort
Abort:    eval_callback returns error text → Qt unfreezes
```

## Data Flow: Shape Management

```
viewer_put_shape(vwr, shape_ptr, name)
  → ViewerState::shapes[name] = AIS_Shape(shape)
  → context->Display(ais_shape, false)
  → emit signal → SceneTreePanel::addShape(name)
  → viewer->fitAll()

viewer_remove_shape(vwr, name)
  → context->Remove(shapes[name], false)
  → shapes.erase(name)
  → emit signal → SceneTreePanel::removeShape(name)

viewer_clear(vwr)
  → context->RemoveAll(false)
  → shapes.clear()
  → emit signal → SceneTreePanel::clearAll()
```

## File Structure

```
qt-viewer/
├── wrap/
│   ├── occt_viewer.h           # C API (extern "C") — 40+ functions
│   ├── occt_viewer.cpp         # C API impl + ViewerState + QApp lifecycle
│   ├── viewer_window.h/.cpp    # QMainWindow (menus, status bar, dock mgmt)
│   ├── viewer_widget.h/.cpp    # QOpenGLWidget + AIS_ViewController
│   ├── repl_panel.h/.cpp       # REPL dock widget
│   ├── scene_tree_panel.h/.cpp # Scene tree dock widget
│   ├── OcctQtTools.h/.cpp      # Qt↔OCCT glue (from occt-samples-qt)
│   └── OcctGlTools.h/.cpp      # GL context/FBO wrappers (from occt-samples-qt)
├── src/
│   └── viewer/
│       ├── package.lisp        # Updated exports
│       ├── bindings.lisp       # CFFI to new C API
│       ├── lifecycle.lisp      # Qt main thread + Swank worker
│       ├── queue.lisp          # Event queue (unchanged logic)
│       └── repl.lisp           # Eval/file-op callbacks (unchanged)
├── CMakeLists.txt              # Qt6 + OCCT build
├── justfile                    # Convenience wrapper
└── start.lisp                  # Entry point
```

## Risks / Trade-offs

| Risk | Impact | Mitigation |
|------|--------|------------|
| Qt REPL eval blocks UI during long computations | UI freezes | Use SLIME for heavy work; post-MVP add async eval path |
| SIGINT during Qt REPL eval enters debugger on main thread | Qt frozen until abort | SLIME still responsive on worker thread; user can abort from there |
| Qt6 not available on all target platforms | Build failure | Document Qt6 requirement; provide alternative for Qt5 if needed |
| OcctNeutralWindow behavior differs across platforms | Visual artifacts | Test on all three platforms before release; fall back to platform-specific window if needed |
| AIS_ViewController API changes between OCCT versions | Compile errors | Pin OCCT version (8.0.0); document in build requirements |
