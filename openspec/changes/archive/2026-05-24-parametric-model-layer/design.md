## Context

ClotCAD is a Qt6-based 3D viewer for cl-occt (a thin Common Lisp OCCT wrapper). cl-occt commit 8ee4a1e removed its parametric DSL and DAG layer (~260 lines of non-OCCT code) to keep the library a clean 1:1 OCCT wrapper. The viewer layer (`src/viewer/`) currently references the removed symbols (`cl-occt.impl:*model-registry*`, `cl-occt.impl:propagate-changes`) leaving dead code.

The removed functionality — `defmodel`, `param`, `with-params`, `model-ref`, `set-param!`, `set-params!`, DAG propagation, model metadata — needs to be restored in ClotCAD's own source. The gating design question is where to draw the boundary between model and viewer layers, and how they communicate.

## Goals / Non-Goals

**Goals:**
- Restore the parametric DSL (`defmodel`, `param`, `with-params`, `model-ref`, metadata accessors)
- Restore the reactive DAG (model registry, dirty propagation, topological evaluation)
- Restore `set-param!` / `set-params!` for parameter-driven shape updates
- Restore DAG-aware STEP I/O (`write-dag-models-to-step`, `read-step-into-dag`)
- Move `resolve-shape` to the model layer (removes dangling reference to cl-occt.impl)
- Change `def` to register in the DAG registry and appear grayed in the Scene Tree
- Change `display` to also register a simple model in the DAG registry
- Remove `undisplay` (superseded by `hide`/`show`)
- Replace monkey-patch on cl-occt's `propagate-changes` with a decoupled hook mechanism
- Consolidate all package definitions into top-level `src/package.lisp`
- Update `docs/clotcad-api.md` and `docs/cheatsheet/cheatsheet.typ` with new API surface

**Non-Goals:**
- No changes to cl-occt submodule (it remains a thin 1:1 OCCT wrapper)
- No changes to C++ wrapper (`wrap/`)
- No changes to CFFI bindings
- No changes to the viewer's rendering pipeline
- No new UI components

## Decisions

### 1. Model layer lives in `src/model/`

Separate module from viewer, with its own files and no dependency on viewer code. Viewer depends on model, not the reverse. Files:

| File | Contents |
|------|----------|
| `model/model.lisp` | `model` struct, `*model-registry*` hash table, `register-model`, `find-model`, `unregister-model` |
| `model/params.lisp` | `*params*` global parameter plist, `*after-propagation-hook*` list |
| `model/propagation.lisp` | `dirty-model!`, `topological-sort`, `evaluate-model`, `propagate-changes` |
| `model/api.lisp` | `defmodel` macro, `set-param!`, `set-params!`, `param`, `with-params`, `model-ref`, `model-color`, `model-display-name`, `model-layer`, `help`, `write-dag-models-to-step`, `read-step-into-dag`, `resolve-shape` |

### 2. DAG registry uses string keys

Both `*model-registry*` and `*displayed-models*` use string keys (the `equal` test). Symbols normalize via `(string name)` on registration and lookup. This eliminates the dual-registry lookup problem in the old `resolve-shape`.

### 3. `resolve-shape` lives in the model layer

```lisp
(defun resolve-shape (designator)
  (etypecase designator
    (cl-occt:shape designator)
    (string  (let ((m (find-model designator)))
               (if m (model-cached-shape m)
                   (error "~S not found" designator))))
    (symbol  (resolve-shape (string designator)))))
```

No dependency on `*displayed-models*`. Callers in `viewer/ops.lisp` import this instead of defining their own.

### 4. `def` registers in DAG + displays grayed

```
(def :box (make-box 10 20 30))
  → 1. Evaluate (make-box 10 20 30)
  → 2. register-model("box", model{:fn=nil, :cached-shape=<box>, ...})
  → 3. Create entry in *displayed-models* (visible=nil, show-in-tree=t)
```

Scene Tree shows "box" as an unchecked grayed entry. The shape is available for boolean ops via `resolve-shape`.

### 5. `display` also registers in DAG

```
(display :box shape)
  → 1. If no model named "box" exists, register-model("box", simple model)
  → 2. Create entry in *displayed-models* (visible=t, show-in-tree=t)
```

This ensures shapes added via `display` are also resolvable by name in boolean operations.

### 6. `show` resolves from registry if needed

```
(show :box)
  → If :box already in *displayed-models*: set visible=t
  → Else: resolve-shape(:box) → add to *displayed-models* (visible=t, show-in-tree=t)
```

### 7. Propagation bridge via hook, not monkey-patch

The model layer defines `*after-propagation-hook*` (a list of functions). The viewer registers `viewer-refresh` on this hook at startup. After `propagate-changes` runs, it calls all hook functions. This replaces the old monkey-patch on `cl-occt.impl:propagate-changes`.

```
model/propagation.lisp:
  (defvar *after-propagation-hook* nil)

  (defun propagate-changes ()
    ... topo sort, re-evaluate ...
    (dolist (fn *after-propagation-hook*) (funcall fn)))

viewer/lifecycle.lisp:
  (push 'viewer-refresh cl-occt.impl:*after-propagation-hook*)
```

Note: `*after-propagation-hook*` is exported from `:clotcad.impl` (the model internals), but the hook symbols live in the model layer's own package. The viewer imports them.

### 8. `viewer-refresh` reads local registry

Replaces the old version that read `cl-occt.impl:*model-registry*`. Now iterates ClotCAD's own `*model-registry*` and updates shapes in `*displayed-models*` for any model that has a cached shape and a display entry.

### 9. `undisplay` removed

`hide`/`show` are sufficient. `clear-all` remains for bulk removal from `*displayed-models*` (DAG registry is unaffected).

### 10. Package definitions consolidated to `src/package.lisp`

All three packages (`:clotcad.impl`, `:clotcad`, `:clotcad-user`) defined in one top-level file, loaded before model and viewer modules. `src/viewer/package.lisp` and `src/model/package.lisp` only switch to existing packages.

### 11. System definition order

```
clotcad.asd:
  :module "package"  → src/package.lisp
  :module "model"    → src/model/
  :module "viewer"   → src/viewer/
```

## Risks / Trade-offs

- **[Breaking change]** `def` no longer returns the shape from the defmacro expansion — it returns the model struct or shape. Check callers that depend on the return value.
- **[API compatibility]** old `resolve-shape` checked `*displayed-models*` first; new one only checks the DAG registry. Viewer wrapper functions (`cut`, `fuse`, etc.) in `ops.lisp` that call `resolve-shape` now get shapes from the model layer, which is fine — they return raw shapes anyway. But `(resolve-shape "name")` for a shape that's only in `*displayed-models*` (not the registry) will now fail. Mitigation: `display` now also registers in the DAG, so this shouldn't happen.
- **[Test coverage]** Existing tests mock CFFI functions but don't cover the DAG/DSL layer. New tests needed for model layer.
- **[Memory]** The DAG registry keeps all models alive. `defmodel` models have closures capturing the model body. No issue for typical usage.
- **[Thread safety]** `propagate-changes` and `set-param!` run on the Slynk worker thread. `*displayed-models*` access from the viewer-refresh hook runs on the same thread (it's the Slynk thread pushing to the Qt event queue). No contention.

## Open Questions

- Should `def` accept optional metadata keywords (`:color`, `:name`, `:layer`) for consistency with `defmodel`? Currently planned as `(def name shape-form)` with no metadata — if users need metadata they use `defmodel`.
- What test strategy for the model layer? ClotCAD tests use `with-mocked-viewer` which mocks CFFI. Model layer tests could avoid the mock entirely (pure Lisp logic) or could use a reduced mock.
