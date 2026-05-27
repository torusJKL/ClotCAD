## Why

The `apropos` command is the primary discovery mechanism in the ClotCAD REPL, but it only supports substring search — you need to already know what you're looking for. A new user (or AI agent) has no way to explore what the system can do. By expanding `apropos` to also show the full API organized by source-file category, discovery becomes possible without prior knowledge of function names.

## What Changes

- `apropos` with no argument shows the category tree (all function groups derived from source files)
- `apropos :<keyword>` shows a specific category's functions with full signatures and docstrings (keyword → category lookup via partial match on display name or filename stem)
- `apropos` with a string or bare symbol retains existing substring search behavior
- `:packages` keyword argument accepts both a single package designator and a list (currently only accepts lists)
- Keywords that match no category return nil / "no category found" — no fallthrough to substring search
- A filename-to-display-name map is introduced to provide human-readable category names
- Categories span both `:cl-occt` and `:clotcad` packages
- Update `docs/clotcad-api.md` with the new `apropos` usage

## Capabilities

### New Capabilities

- `apropos-categories`: The `apropos` command supports category browsing via keyword lookup and no-argument category tree display. Functions are grouped by source file, with human-readable display names. Covers both `:cl-occt` and `:clotcad` packages.

### Modified Capabilities

<!-- No existing specs to modify -->

## Impact

- `src/viewer/introspect.lisp`: Rewrite `apropos-impl` and `apropos` macro to support optional pattern, keyword category lookup, and category tree display. Add `sb-introspect` dependency for source file introspection.
- `src/package.lisp`: No API-external changes needed (apropos already exported).
- `docs/clotcad-api.md`: Update `apropos` documentation to describe new modes.
- `lib/cl-occt/` (not modified directly): The category map references cl-occt's source files but lives in clotcad's codebase.
