## Context

ClotCAD is a Common Lisp application with packages `clotcad.impl` (implementation), `clotcad` (public API), and `clotcad-user` (user workspace). New macros need to be defined in `clotcad.impl` and exported from both `clotcad.impl` and `clotcad` to be accessible from `clotcad-user`. The ASDF system uses serial loading in `clotcad.asd`, so the new file must be inserted at the correct position in the load order.

## Goals / Non-Goals

**Goals:**
- Provide `->`, `->>`, and `as->` threading macros matching Clojure semantics
- Export from the `clotcad` package so they're available in `clotcad-user`
- Load early enough that any code (including model/viewer modules) can use them
- Full test coverage including edge cases (no forms, single form, symbol forms, nested threading)

**Non-Goals:**
- Other threading variants like `some->`, `cond->`, `doto` — user can request in future
- Macros that interact with ClotCAD's shape/model system — these are generic utilities
- Performance optimization beyond standard macro expansion

## Decisions

- **New file `src/threading.lisp`** rather than piggybacking on existing files. Keeps the macros isolated and easy to find. Follows the pattern of the codebase (one concern per file).
- **Loaded after `package` but before `model` and `viewer` modules** in `clotcad.asd`. Since serial `t` is used, insert a `"threading"` string component after `"package"` in the `:components` list. This makes the macros available to all downstream code.
- **Reduce-based implementation** rather than recursive. `reduce` with `:initial-value` processes forms left-to-right naturally, producing a single nested form. No need for explicit recursion or gensym management.
- **Symbol-form handling**: When a form is a bare symbol (not a list), treat it as a function call with the threaded value as its sole argument (e.g., `(-> x f)` → `(f x)`). This matches Clojure behavior.
- **Package placement**: Define in `clotcad.impl` like all other internal code. Export from `clotcad` so `clotcad-user` sees them. This follows the existing convention for all public API symbols.

## Risks / Trade-offs

- **Symbol name readability**: `->` and `->>` are valid Common Lisp symbols but may visually blend with accessor notation (`slot-value` style). Mitigation: consistent documentation and cheatsheet entry.
- **Package conflicts**: `->` and `->>` are uncommon enough that conflicts are unlikely, but if a dependency uses them, `clotcad`'s exports would shadow them. Mitigation: minimal risk — no current dependency uses these names.
