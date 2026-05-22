## Why

The REPL history export only captures evaluations entered through the UI REPL panel. Evaluations performed via Slynk (port 4005, from SLY-enabled editors) or Alive LSP (port 4006, from LSP clients like VS Code) are invisible to the export system, making the exported history incomplete and less useful for documentation, debugging, or notebook-style workflows.

## What Changes

- Intercept evaluations from the Slynk thread and push them into `*repl-log*`
- Intercept evaluations from the Alive LSP thread and push them into `*repl-log*`
- Both code-only entries and code+output entries are recorded, respecting `*export-with-output*` on export
- No change to the export API (`export-repl-history`, `result-export`, `*export-with-output*`) — it already handles all entries uniformly

## Capabilities

### New Capabilities
- `remote-repl-capture`: Capture evaluations from Slynk and Alive LSP connections into the REPL history log

### Modified Capabilities
<!-- None — no existing specs to modify -->

## Impact

- **`src/viewer/repl.lisp`**: Add logging calls in Slynk and Alive eval paths (or provide hooks they call)
- **`src/viewer/lifecycle.lisp`**: Wire up the capture mechanism when starting Slynk and Alive
- **`lib/alive-lsp/`**: May need a small patch to expose eval results (similar to the existing `:default-package` patch)
- **`src/viewer/package.lisp`**: May export new functions if needed
- No change to the export system itself — it consumes `*repl-log*` entries generically
