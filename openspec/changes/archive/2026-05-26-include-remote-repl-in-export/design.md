## Context

The REPL history (`*repl-log*`) is a flat list of `(code . output)` cons cells populated by two paths: the UI REPL callback (`eval-string`) and Lisp file import (`process-import-tick`). The export system (`export-repl-history`) iterates `*repl-log*` in reverse and writes code (and optionally output) to a file.

Slynk runs on port 4005 in a dedicated SBCL thread. Its evaluations use Slynk's own protocol (`swank`) and never touch `*repl-log*`. Alive LSP runs on port 4006 in another dedicated thread. Its evaluations use `alive/sys/eval:eval-fn` (a wrapped `eval`), capture stdout/stderr via callbacks, and send results as LSP messages — but never push to `*repl-log*`.

Both threads share the same Lisp image and can access the viewer's global state, including `*repl-log*`.

## Goals / Non-Goals

**Goals:**
- Every evaluation from Slynk is recorded in `*repl-log*` with its code and output
- Every evaluation from Alive LSP is recorded in `*repl-log*` with its code and output
- Existing `export-repl-history` and `result-export` work unchanged — they already read all entries
- No user-visible API changes unless strictly necessary

**Non-Goals:**
- No changes to the export system or `*repl-log*` data format
- No changes to the C++ layer or CFFI bindings
- No changes to the UI REPL panel or import system
- No real-time push of remote eval output to the UI REPL display (only to the log)
- No history size limit or log rotation (same behavior as current system)

## Decisions

- **Hook into Alive LSP eval handler** — The existing `:default-package` patch (in `lib/alive-lsp/src/session/handler/eval.lisp`) already intercepts the eval path. Add a logging call there that pushes to `*repl-log*` via a provided callback function. Alternative: modify `alive/sys/eval:eval-fn` — rejected because it's further from where output is captured.
- **Wrap Slynk's eval** — Slynk provides the `swank:*sldb-princ-limit*` and output redirection machinery. We can wrap `swank:swank-eval` or install an `swank:connection` output hook that captures eval results and pushes to `*repl-log*`. Alternative: advice on `swank:eval-for-emacs` — simpler but less access to captured output. Decision: use advice on `swank:eval-for-emacs` since Slynk already captures output into its result string.
- **Provide a shared logging function** — A single function `log-remote-eval` in `repl.lisp` will be called from both paths, accepting a code string and an output string. This keeps the logging logic in one place and avoids code duplication.
- **Thread safety — use `sb-ext:atomic-push`** — `*repl-log*` is currently mutated only from the Qt main thread (safe despite using non-atomic `push`). Slynk and Alive threads will call `log-remote-eval` from their own threads, introducing true concurrency. SBCL's `push` is not atomic (it is a read-CONS-setf sequence). Two concurrent pushes can silently lose entries. Fix: use `sb-ext:atomic-push` (CAS-based retry loop) at all three mutation sites: `eval-string` (repl.lisp:90), `process-import-tick` (repl.lisp:47), and `log-remote-eval`. Export reads in `export-repl-history` are safe because `atomic-push` guarantees a consistent list state. Alternative: drain via queue (push to `*viewer-queue*`, process on Qt main thread) — rejected as more complex with no benefit.

## Risks / Trade-offs

- **[Race on export]** If `export-repl-history` iterates `*repl-log*` while a remote eval is in `atomic-push`, the iteration may miss the most recent entry. Mitigation: acceptable — `atomic-push` guarantees the list is always consistent (no torn writes), so iteration is safe; a stale read (missing the very latest entry) is fine for export.
- **[No UI feedback]** Remote eval entries are added silently to `*repl-log*` but not shown live in the REPL panel. Mitigation: this is a conscious non-goal; the user asked only for export inclusion.
- **[Slynk patch coupling]** Using advice on `swank:eval-for-emacs` ties us to Slynk's internal eval API. Mitigation: Slynk is bundled with SBCL and stable; the advice hook is minimal and easy to update if the API changes.
- **[Alive LSP patch coupling]** Additional patch surface on `lib/alive-lsp/`. Mitigation: the existing `:default-package` patch already sets the precedent; our addition is one more function call in one more file.
