## Context

Currently, when `map-shape-subshapes` returns a list of faces, the caller gets anonymous shape objects. There is no way to say "remember this specific face for later." The model struct tracks named models but has no facility for named subshapes.

## Goals / Non-Goals

**Goals:**
- Allow users and AI agents to give stable names to subshapes.
- Names survive as long as the parent model exists (even after shape recomputation via defmodel).
- Named subshapes appear in the Scene Tree as nested children.
- Compound symbols (`:my-box/top-face`) work wherever shape designators are accepted.

**Non-Goals:**
- Persistent naming across modeling operations (topological re-identification after boolean ops). Named subshape queries are re-evaluated on each access.
- Integration with OCAF naming.
- Modifying the OCCT or cl-occt layer.

## Decisions

### D1: Named subshapes are stored queries, not cached pointers
`:my-box/top-face` stores a query that is re-evaluated on access via `face-ref`.
- **Rationale**: Survives shape recomputation (e.g., defmodel param changes). No stale pointer risk.

### D2: Parent model is never mutated
`(def :box (make-box 10 20 30))` registers a new model. Operations like `cut` return a new shape for a new `def`. The original `:box` stays unchanged.
- **Rationale**: Named subshapes on `:box` always resolve correctly. No lifecycle management.

### D3: Model struct extension
The `model` struct gains a `named-subshapes` slot (alist of `(name . query-plist)`). Each query-plist stores `:where` and `:coordinate-system` for re-evaluation.

### D4: Compound symbol resolution
A compound symbol `:model/name` is parsed by splitting on `/`. The model part is resolved via `find-model`, the name part via the model's `named-subshapes` alist. This resolution is added to `resolve-shape`.

## Risks / Trade-offs

- **[Performance] Re-evaluation on every access** — For shapes with many faces, each `face-ref` call traverses topology. Mitigation: cache the last result, invalidate only when the model's `cached-shape` pointer changes.
- **[Scene tree] Subshape highlight needs C++ support** — Current viewer selects by model name, not subshape. Mitigation Phase 1: just display names in REPL. Phase 2: add CFFI for subshape AIS selection.

## Open Questions

- Should subshape highlighting in the 3D view use existing AIS selection modes (face/edge/vertex filter + detected interactive) or require a new CFFI binding?
