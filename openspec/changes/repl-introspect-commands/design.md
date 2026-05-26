## Context

The ClotCAD REPL (in `src/viewer/repl.lisp`) evaluates forms in `:clotcad-user` and returns output via a string buffer. There is currently no built-in way to:

1. Look up a symbol's docstring without specifying its type (`'function`, `'variable`)
2. Discover API symbols matching a pattern with a clean, scoped output

The codebase has rich docstrings on almost every public function — the missing piece is ergonomic access.

Both functions must be thread-safe (callable from Qt REPL thread, Slynk thread, and Alive LSP thread). They are pure read-only operations.

## Goals / Non-Goals

**Goals:**

- Provide `(doc name)` that shows docstring and arglist for any symbol type
- Provide `(apropos pattern)` that searches symbols, default-scoped to ClotCAD API
- Both functions work in development and in SBCL core dump distributions
- Both functions are exported from `:clotcad` and available in `:clotcad-user`
- Update `help()`, `docs/clotcad-api.md`, and cheatsheet

**Non-Goals:**

- Not a full SLY/SLIME feature replacement (no source display, no cross-referencing)
- No GUI integration — just REPL commands
- No new dependencies beyond what SBCL provides

## Decisions

### Decision: `doc` is a macro, not a function

In Clojure, `(doc make-box)` works because symbols are resolved differently. In Common Lisp, `(doc make-box)` would evaluate `make-box` as a variable reference, causing an `UNBOUND-VARIABLE` error. Making `doc` a macro that auto-quotes bare symbols solves this: `(doc make-box)` expands to `(doc-impl 'make-box)`. Strings and `#'function` forms pass through unquoted.

The implementation lives in `doc-impl` (function) + `doc` (macro) pair.

### Decision: `apropos` is a macro (same reason, with package lock workaround)

Same quoting issue as `doc` — `(apropos box)` would error. Made it a macro backed by `apropos-impl`.

**Package lock**: `cl:apropos` is a standard Common Lisp function. Defining our own `apropos` in `:clotcad` (which `:use`s `:cl`) triggers SBCL's package lock. Fixed with `(:shadow :apropos)` in the `:clotcad` defpackage, and `(:shadowing-import-from :clotcad :apropos)` in `:clotcad-user`.

### Decision: New file `src/viewer/introspect.lisp`

Both macro/function pairs live in a dedicated file rather than adding to `repl.lisp`. This keeps concerns separated: REPL plumbing (`repl.lisp`) vs. introspection utilities (`introspect.lisp`).

The file was added to `clotcad.asd` in the `viewer` module, after `repl.lisp` and before `ui.lisp`.

**Alternatives considered:**
- Adding to `repl.lisp` — it's already 401+ lines; would push it well past 500
- Adding to `api.lisp` — that's model-layer API, not REPL utilities
- Separate file in `src/model/` — doesn't fit conceptually; these are REPL tools

### Decision: Use `sb-kernel:%fun-lambda-list` for arglist extraction

SBCL's internal `sb-kernel:%fun-lambda-list` extracts the lambda list from any compiled function object. It's what SLIME/SLY use internally for `arglist-string`.

**Why it wins over `sb-introspect:function-lambda-list`:**
- No `(require :sb-introspect)` needed — always available in SBCL
- Works identically in FASL-loaded code and core dumps
- Proven stable for 15+ years of SLIME/SLY use

**Fallback:** If `%fun-lambda-list` errors (CFFI callbacks, foreign functions), catch and skip the arglist display.

**Implementation note:** The lambda list printer uses `%print-lambda-list` and `%print-lambda-list-item` as separate top-level functions rather than `flet` + `loop`, because SBCL's compiler fails to resolve `flet` bindings inside `loop` macro-expanded code.

### Decision: `doc` tries documentation types in fixed order

Order: `function` → `variable` → `type` → `structure` → `class`

This mirrors the likelihood of what the user wants — most lookups are for functions/macros, then variables, then types.

If nothing is found, print a clear "no documentation" message.

**Class docs guarded:** `(documentation sym 'class)` emits warnings on non-class symbols. Guarded with `(find-class sym nil)` to skip non-class symbols silently.

### Decision: `apropos` defaults to `(:clotcad :cl-occt)` packages

The user will almost always be searching for ClotCAD or cl-occt API symbols. Searching all 60+ packages in a typical SBCL image would be noisy.

**`packages` keyword behavior:**
- Default `nil` → search `:clotcad` and `:cl-occt`
- `(apropos "foo" :packages t)` → search all packages (like CL's `apropos`)
- `(apropos "foo" :packages '(:cl))` → search specific packages

### Decision: Output groups by package with type annotations

Flat list of symbols is hard to scan. Grouping by package (like Clojure's `apropos`) with type indicators lets users quickly identify what they're looking for.

Type detection uses `fboundp`, `boundp`, `macro-function`:

```
CLOTCAD:
  make-box (function)
  *params* (variable)
  defmodel (macro)
```

Results are sorted by package name, then by symbol name within each package.

**Alternative considered:** Flat ungrouped list — rejected as harder to scan.

### Decision: `doc-impl` string lookup searches multiple packages

When given a string argument like `(doc "cancel-import")`, `find-symbol` with no package arg searches only the current `*package*`. This fails when called from contexts where the package isn't `:clotcad` (e.g., batch `--eval` or Slynk). Fixed by searching `*package*`, then `:clotcad`, then `:cl-occt` in order.

### Decision: Capture `*standard-output*` in GUI REPL eval

The `eval-string` callback in `repl.lisp` captures return values via `multiple-value-list` but doesn't capture `*standard-output*`. This means `format t` output from `doc`, `apropos`, `help()`, or any printed output goes to the terminal instead of the GUI REPL panel.

Fixed by rebinding `*standard-output*` to a string stream during `eval` and merging printed output with return-value output in the result buffer. Applied to both `eval-string` (GUI REPL) and `process-import-tick` (Lisp file import).

## Risks / Trade-offs

- **`sb-kernel:%fun-lambda-list` is an SBCL internal** — If SBCL ever changes or removes this function, `doc` will lose arglist display. Mitigation: add a conditional fallback that just skips arglist on error.
- **Case sensitivity in `apropos`** — CL symbols are stored uppercase internally. Case-insensitive matching is provided by comparing both `(string-downcase str)` with `(string-downcase symbol-name)`. This matches Clojure's behavior.
- **`help()` grows mentions** — Minor maintenance burden to update the help text when new commands are added. Acceptable.

## Open Questions

- Should `doc` accept CLOS objects or just symbols? (Current scope: symbols and function objects)
- Should `apropos` have a `:external-only` option to filter out internal symbols? (Defer unless requested)
