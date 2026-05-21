## REVISED: Qt REPL restored

### Restored: Qt REPL dock widget

The Qt REPL panel was initially removed as part of the migration, then
restored because the in-window REPL + Swank dual workflow is preferred
for interactive use. The C++ widget is a thin UI shell; all eval logic
remains in Lisp.

**Restored files:**
- wrap/repl_panel.h
- wrap/repl_panel.cpp

**Restored C API:**
- eval_fn typedef
- viewer_set_eval_callback (propagates to REPLPanel via findChildren)
- viewer_append_repl_output (thread-safe via QueuedConnection)

**Restored Lisp bindings:**
- %viewer-set-eval-callback
- %viewer-append-repl-output

**Restored C++ members:**
- ViewerWindow::myRepl
- ViewerWindow::myReplAction

### Restored: Inline eval callback

- The eval_string CFFI callback is present in repl.lisp
- *repl-accumulator* and *repl-eof-sentinel* variables are present

### Requirement: Dual REPL workflow

- **WHEN** the viewer starts
- **THEN** Swank SHALL be available on port 4005 (unchanged)
- **THEN** a Qt REPL dock widget SHALL be visible on the right
- **THEN** Lisp code can be evaluated either in the Qt REPL or via SLIME
- **THEN** the register-viewer-callbacks function SHALL set the eval
        callback
