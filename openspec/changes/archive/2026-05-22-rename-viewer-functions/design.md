## Context

The `cl-occt-viewer` package exports `fit-all` and `set-antialiasing`, which conflict with identically-named symbols exported by `cl-occt`. This prevents creating a clean workspace package that `:use`s both. The root cause is that the viewer's convenience wrappers (operating on the global `*viewer*` singleton) are named identically to cl-occt's library-level functions (which take an explicit viewer object).

## Goals / Non-Goals

**Goals:**
- Eliminate the symbol conflict so `:cl-occt-user` can `:use` both packages without shadowing
- Provide a workspace package where users type `(make-sphere 20)` and `(display :s (make-sphere 20))` without prefixes
- Better API clarity: viewer convenience functions should describe what they act on
- Landing in the workspace package on REPL connect

**Non-Goals:**
- Not refactoring the underlying C++ widget vs OCCT C API duality (that's a separate concern)
- Not renaming other viewer functions (`display`, `show-grid`, etc.) — they don't conflict

## Decisions

### 1. Rename: `fit-all` → `fit-view`

"Fits the view to all displayed shapes" → `fit-view` is shorter and unambiguously about the viewport.

### 2. Rename: `set-antialiasing` → `set-view-aa`

The `-aa` suffix is conventional for antialiasing, and `view-` scopes it to the render view.

### 3. Workspace package: `:cl-occt-user`

Defined in `src/viewer/package.lisp` alongside the other viewer packages. Uses both `:cl-occt` and `:cl-occt-viewer` with no shadowing needed. Nicknames `:cad-user` and `:occt-user` for quick `(in-package :cad-user)`.

```lisp
(defpackage :cl-occt-user
  (:use :cl :cl-occt :cl-occt-viewer)
  (:nicknames :cad-user :occt-user))
```

Chose `:cl-occt-user` over alternatives:
- `:cad-user` — too generic, could conflict with other CAD systems
- `:occt-user` — fine but less conventional CL naming
- No `:import-from` needed since conflicts are eliminated

### 4. Startup: `start.lisp` → `(in-package :cl-occt-user)`

Both the main thread and Swank worker thread will land in `:cl-occt-user`, giving immediate unqualified access to everything.

## Risks / Trade-offs

- **[Name change breaks muscle memory]** Existing users who type `(fit-all)` in the REPL will get an error. Mitigation: announce change clearly, and include an upgrade note in README. The functions were short-lived, so impact is minimal.
- **[`cl-occt-user` collides with a future ASDF system]** Unlikely, but using the `:cl-` prefix follows CL convention (`:cl-user`, `:cl-sql`, etc.). Proceed.
