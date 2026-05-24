## Context

ClotCAD runs in three modes (`--viewer`, `--slynk`, `--alive`), each starting a subset of services (viewer GUI, Slynk server, Alive LSP server). Currently there is no unified shutdown path that can be triggered from a remote REPL connection. `stop-viewer` only stops the render loop and calls `%viewer-quit` — it does not call `%viewer-destroy` (leaking C++ memory), does not stop Slynk or Alive LSP, and does not reset Lisp state. `wait-forever` only handles SIGINT. Remote users must rely on process signals or window close events.

## Goals / Non-Goals

**Goals:**
- Create a single `(quit-clotcad)` function callable from any REPL (in-window, SLY, Alive LSP) that stops all services and exits cleanly
- Support all three run modes: `--viewer`, `--slynk`, `--alive`
- Properly tear down the C++ viewer state (`%viewer-destroy`) to avoid memory leaks
- Reset Lisp state globals on shutdown
- Fix the `"CL-OCCT-USER"` → `"CLOTCAD-USER"` rename artifact in `start-alive`

**Non-Goals:**
- Hot-restart of services without process exit (out of scope; may be added later)
- Graceful in-flight operation cancellation beyond what already exists
- Changes to the existing `stop-viewer` or `wait-forever` APIs

## Decisions

### 1. Single function for all modes, not mode-specific variants

**Decision:** `quit-clotcad` detects which services are running and stops them accordingly, working identically in all three modes.

**Rationale:** The user shouldn't need to know which mode they're in. A single universal command is simpler to document, remember, and maintain.

### 2. `sb-ext:quit` as the exit mechanism

**Decision:** After stopping all services, call `(sb-ext:quit)` to terminate the Lisp process.

**Rationale:** This is the standard SBCL clean exit path already used in `scripts/start.lisp` and `wait-forever`. It handles thread cleanup, finalizers, and stream flushing. Alternatives like `(sb-thread:terminate-thread ...)` on each service thread are fragile and leave the process in an inconsistent state.

### 3. `find-symbol` for optional service shutdown

**Decision:** Use `find-symbol` to locate `slynk:stop-all-servers` and `alive/server:stop` — same pattern as `start-slynk` and `start-alive` use for their startup symbols.

**Rationale:** Slynk and Alive LSP are optional dependencies (checked at runtime). The `find-symbol` pattern already established in `lifecycle.lisp` handles the case where the library isn't loaded, without a hard dependency. The code gracefully degrades to a warning if a stop symbol isn't found.

### 4. Sequential shutdown order: services first, then viewer, then exit

**Decision:** Stop order: Slynk → Alive LSP → render loop → viewer (quit + destroy) → reset Lisp state → `sb-ext:quit`.

**Rationale:** Stopping Slynk/Alive first prevents new remote eval requests during teardown. Stopping the render loop before the viewer prevents redraw attempts on a destroyed viewer. The viewer destroy is the last service step because it blocks on Qt event loop exit. `sb-ext:quit` is the final step.

### 5. Add `%viewer-destroy` call to the C++ teardown path

**Decision:** Call `%viewer-destroy` after `%viewer-quit` in `quit-clotcad` (currently `stop-viewer` only calls `%viewer-quit`).

**Rationale:** The C++ `ViewerState` and associated objects are never freed. `viewer_destroy` deletes the `ViewerWindow` (and child widgets) and frees the `ViewerState` struct. This is a memory leak fix.

## Risks / Trade-offs

- **Slynk/Alive stop functions may not exist in all versions** → Use `handler-case` around stop calls, fall back to warning if not found
- **`quit-clotcad` disconnects the caller** → This is expected behavior; the client will see a connection drop and reconnect if needed. Document clearly.
- **Race with in-flight eval** → The Qt event loop drain callback processes pending queue items. Stopping Slynk/Alive first prevents new eval requests, and `%viewer-quit` unblocks `%viewer-run`, allowing the event loop to drain naturally. No explicit drain needed.
- **Process may not fully exit if finalizers hang** → `sb-ext:quit` with no arguments uses `0` exit code. If hanging occurs, users can fall back to SIGINT. This is existing behavior, not new.
