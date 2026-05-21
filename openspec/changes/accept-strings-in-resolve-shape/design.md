## Context

`resolve-shape` in `src/viewer/ops.lisp` dispatches on type via `etypecase`:
- `cl-occt:shape` — passed through directly
- `symbol` — converted to string via `(string designator)` then looked up in `*displayed-models*`, with fallback to `cl-occt.impl:*model-registry*`

`display` in `src/viewer/queue.lisp` stores entries under string keys (via `(string name)`). The `def` macro also uses `(string ',name)`, which already works for string literals. But `resolve-shape` has no `string` branch, so any operation on a string-named shape fails at the `etypecase`.

The fix is minimal: add a `string` branch that mirrors the symbol lookup path but skips the `string` conversion (since the key is already a string), and does not fall back to `*model-registry*` (which uses symbol keys, not string keys).

## Goals / Non-Goals

**Goals:**
- Enable `(cut :s "box2")` and all other shape operations to accept string designators
- Consistent behavior: strings look up directly in `*displayed-models*`, same as symbols after conversion
- Proper error when unknown string is passed
- Test coverage for string resolution

**Non-Goals:**
- No changes to `display`, `def`, `undisplay`, or `clear-all` — they already handle strings
- No changes to the `*model-registry*` fallback (not applicable for string keys)
- No performance optimization beyond the straightforward lookup

## Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| String branch approach | Direct `gethash` + error if missing | Matches symbol behavior after `(string ...)` conversion; no fallback to `*model-registry*` since that uses symbol keys |
| No `sname` local variable | Use `designator` directly | `designator` is already a string; no conversion needed |

Implementation:

```lisp
(string (let ((entry (gethash designator *displayed-models*)))
           (if entry
               (first entry)
               (error "~S does not name a known shape" designator))))
```

## Risks / Trade-offs

- **[Low] Case sensitivity**: String keys are case-sensitive (unlike symbols where `(string :my-shape)` → `"MY-SHAPE"`). This is consistent with how `display` / `def` already work — `(def "box2" ...)` and `(display :s ...)` produce different keys. User education (via README) is sufficient.

## Open Questions

None.
