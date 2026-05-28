## Context

The `apropos` macro in `src/viewer/introspect.lisp` is a ClotCAD API browser that shadows `cl:apropos`. The `help` function in `src/model/api.lisp` hard-codes a categorized function listing that duplicates what `browse` dynamically discovers from source introspection. As the API grows, `help` requires manual updates to stay in sync.

The name `browse` was chosen over alternatives (`explore`, `catalog`, `search`) because:
- It's a verb, so `(browse)` reads naturally as a command
- It accurately covers all three modes (browse the catalog, browse a category, browse search results)
- It pairs with `doc`: "browse to find something, doc to learn about it"
- It doesn't shadow any CL symbol

## Goals / Non-Goals

**Goals:**
- Rename `apropos` → `browse` across all source, tests, package definitions, and docs
- Remove `(:shadow :apropos)` from `:clotcad` defpackage (no longer needed)
- Remove `(:shadowing-import-from :clotcad :apropos)` from `:clotcad-user` (no longer needed)
- Simplify `help` to a minimal quick-start with visual feedback examples
- Redirect all internal `"See also:"` and format-string references from `apropos` → `browse`

**Non-Goals:**
- No behavior changes to the three browse modes (tree, category drill-down, substring search)
- No alias or backward-compat shim for `apropos` — clean break
- No changes to archived change documents (historical records)

## Decisions

### Decision: Name `browse` over alternatives
- `explore` — slightly longer, same fit but less concise
- `catalog` — more formal, awkward with search mode ("catalog \"box\"")
- `search` — only covers one of three modes
- `?` — Lispy but awkward for `(? :category)` and conflicts with character-macro conventions
- **Chosen**: `browse`

### Decision: No backward-compat alias
The shadowing itself was the problem — keeping `apropos` as an alias would still shadow `cl:apropos` (or require not exporting it, creating discovery confusion). A clean rename avoids all future confusion. The rename is mechanical and grep-able.

### Decision: Help minimalism
Current `help` lists every function in categories — a maintenance burden. Simplified version shows:
1. Project tagline
2. Pointers to `(browse)` and `(doc ...)` as the discovery tools
3. One quick-start example that gives immediate visual feedback: `(display "my-box" (make-box 10 10 10))`
4. Brief quick-reference for the most essential commands (primitives, booleans, defmodel)

This is intentionally minimal — `browse` and `doc` are the primary discovery mechanisms.

### Decision: Internal function renames
Keep the internal naming convention consistent:
- `apropos-impl` → `browse-impl`
- `%apropos-tree` → `%browse-tree`
- `%apropos-category` → `%browse-category`
- `%apropos-substring-search` → `%browse-substring-search`

### Decision: Spec updates
Existing specs in `openspec/specs/repl-introspect/symbol-apropos-search/` and `openspec/specs/repl-introspect/apropos-categories/` are replaced with delta specs that rename all refs from `apropos` to `browse`. The `openspec/specs/repl-introspect/spec.md` file itself (if any) is also checked for refs.

## Risks / Trade-offs

- **[Breakage] External code using `clotcad:apropos`** — The function was newly introduced in this project version and not widely used externally. Clean rename is acceptable.
- **[Maintenance] Help drift** — Minimal help reduces but doesn't eliminate drift risk. The quick-start example `(make-box 10 10 10)` is unlikely to change.
- **[Tests] Test function names** — Tests use `deftest apropos-*` naming; all rename to `browse-*` for consistency.
