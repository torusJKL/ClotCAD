## Context

The viewer currently supports STEP/STL import/export (data only) and a synchronous REPL where user-typed Lisp forms are `eval`'d one at a time on the Qt main thread. The REPL input is stored in C++ (`myHistory`, max 1000 entries), output is a plain text widget. There is no mechanism to load a batch of forms from a file or to save a session log.

The threading model has three threads: Qt main thread (UI, REPL eval, file ops, paintGL), Swank worker thread (SLIME eval, queued dispatch), and a render-loop thread (periodic redraw). The queue system (`queue.lisp`) dispatches shape operations from Swank to the Qt main thread via WakeEvent.

## Goals / Non-Goals

**Goals:**

- Allow users to import a `.lisp` file and have each form evaluated sequentially on the Qt main thread, with the UI remaining responsive between evaluations.
- Provide cancellation of an in-progress import (checked between forms).
- Allow users to export REPL history to a `.lisp` file, with or without result output.
- Echo all imported forms and their results to the REPL in real-time.
- Warn users prominently before executing code from a Lisp file.

**Non-Goals:**

- Sandboxing or restricting what Lisp code can do during import — the danger dialog is a warning, not a guard.
- Optimizing the existing `*displayed-models*` race condition between Qt main and Swank threads — that's pre-existing and out of scope.
- A graphical import progress bar (status bar text is sufficient).
- Importing compiled Lisp files (`.fasl`, `.so`) — only source `.lisp` files.
- Editing the exported history before writing — export is a dump of the log, not an editor.

## Decisions

### Decision 1: Tick-based evaluation via WakeEvent + drain-queue extension

The import processes one form per tick. Each tick is triggered by a WakeEvent, and the import logic runs as an additional phase at the end of `drain-queue`. Between ticks, Qt's event loop processes freely (mouse, paintGL, keyboard), keeping the UI responsive.

**Alternatives considered:**
- **Synchronous eval in handle-file-op** — rejected because it blocks the Qt main thread for the entire file, freezing the UI and preventing cancellation.
- **Separate thread for import** — rejected because the user wants "same thread as the REPL" (Qt main thread) for predictable semantics and no new thread-safety concerns.
- **QTimer-based eval from C++** — requires a new callback type and more C++ surface; the existing WakeEvent mechanism does the same job.

### Decision 2: Delayed event posting for replay speed

A single new C function `viewer_post_event_delayed(vwr, ms)` is added, wrapping `QTimer::singleShot` → `WakeEvent`. This lets Lisp control timing without any C++ timer infrastructure — each tick schedules the next one with the current `*import-speed*` value, which the user can change dynamically via `(replay-speed N)`.

**Alternatives considered:**
- **Persistent QTimer with dynamic interval** — requires start/stop/restart logic and a new callback; over-engineered for what's essentially "schedule next event after N ms."

### Decision 3: All import state lives in Lisp

No new C++ state or callback types are introduced for the import engine. The import state machine (`*import-forms*`, `*import-index*`, `*import-speed*`, `*import-cancelled*`) is entirely Lisp-side, processed inside `drain-queue`. The C++ side only adds the menu item, the danger dialog, the status bar label, the cancel shortcut, and the delayed post-event function.

**Rationale:** Minimizes C++ surface area, keeps logic in Lisp where it's easier to maintain and test, and reuses the existing WakeEvent → drain-queue pipeline.

### Decision 4: REPL log captured on Lisp side

Rather than parsing the C++ output widget, `*repl-log*` is captured directly in the Lisp `eval-string` callback and in `process-import-tick`. Each entry is a `(input-string . output-string)` pair. The clean/debug mode is controlled by the `*export-with-output*` Lisp variable, toggled via `(result-export t/nil)`.

**Rationale:** The C++ widget is presentation; the Lisp log is the authoritative record. Avoids fragile text parsing.

### Decision 5: Cancellation via three channels

- **REPL function** `(cancel-import)` — sets `*import-cancelled*` to `t`
- **Keyboard shortcut** Ctrl+G — C++ `QShortcut` on the main window that calls a C function which triggers the Lisp cancel (or directly pushes it as a callback)
- **Status bar clickable label** — shown during import, triggers same Lisp cancel call

The flag is checked at the TOP of each `process-import-tick`, before any form is evaluated. A form currently being `eval`'d runs to completion.

## Risks / Trade-offs

- **[Freeze during long OCCT calls]** If a form calls `cl-occt:cut` that takes 30 seconds, the UI freezes for 30 seconds. Cancellation only works between forms, not mid-form.
  - **Mitigation**: This is identical to what happens when the user types the same form in the REPL. Documented behavior. Users can set a low `replay-speed` to make the between-form responsiveness useful.

- **[Race with Swank on *displayed-models*]** If the user simultaneously evaluates code from SLIME during an import, `*displayed-models*` is accessed from both the Qt main thread (import `eval` may call `display`) and the Swank thread. This is a pre-existing issue.
  - **Mitigation**: Out of scope for this change. The import runs on the same thread as the REPL, so it does not introduce new races. The user is responsible for not interleaving Swank eval during import.

- **[Memory growth from *repl-log*]** The log grows unboundedly during a session, potentially using significant memory for long sessions with large outputs.
  - **Mitigation**: This is a pre-existing concern (the output widget already caps at 10K lines). A future enhancement could cap `*repl-log*` size. For now, the user can restart the viewer to clear it.

- **[Danger dialog habituation]** Users may click through the warning dialog without reading it, especially if they import Lisp files frequently.
  - **Mitigation**: The dialog text is deliberately strong ("You are about to execute arbitrary Lisp code... full access to your system"). No "Don't show again" checkbox is provided.
