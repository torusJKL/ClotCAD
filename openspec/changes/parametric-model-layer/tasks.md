## 1. Package refactoring

- [ ] 1.1 Move all three `defpackage` forms from `src/viewer/package.lisp` to new `src/package.lisp`
- [ ] 1.2 Update `clotcad.asd` to load `:module "package"` (from `src/package.lisp`) before model and viewer modules
- [ ] 1.3 Update `src/viewer/package.lisp` to use `in-package` only (no defpackage)

## 2. Model layer — core data structures

- [ ] 2.1 Create `src/model/package.lisp` with `in-package` forms
- [ ] 2.2 Create `src/model/model.lisp` with `model` struct (name, fn, param-keys, model-deps, dependents, dirty, cached-shape, last-param-hash, color, display-name, layer), `*model-registry*` hash table, `register-model`, `find-model`, `unregister-model`
- [ ] 2.3 Create `src/model/params.lisp` with `*params*`, `*after-propagation-hook*`

## 3. Model layer — propagation

- [ ] 3.1 Create `src/model/propagation.lisp` with `dirty-model!` (marks model + dependents dirty recursively)
- [ ] 3.2 Implement `topological-sort` with cycle detection
- [ ] 3.3 Implement `evaluate-model` (checks dirty flag and param hash, re-evaluates if needed)
- [ ] 3.4 Implement `propagate-changes` (collect dirty models, topo-sort, evaluate each, fire `*after-propagation-hook*`)

## 4. Model layer — API

- [ ] 4.1 Create `src/model/api.lisp`
- [ ] 4.2 Implement `resolve-shape` (symbol/string/shape → cached shape from registry)
- [ ] 4.3 Implement `param` (reads from `*local-params*` or `*params*`)
- [ ] 4.4 Implement `with-params` macro
- [ ] 4.5 Implement `defmodel` macro (parse metadata clauses, collect model-ref deps, detect param keys, register model, generate keyword function)
- [ ] 4.6 Implement `model-ref`, `model-color`, `model-display-name`, `model-layer`
- [ ] 4.7 Implement `set-param!` and `set-params!`
- [ ] 4.8 Implement `write-dag-models-to-step` and `read-step-into-dag`
- [ ] 4.9 Implement `help`

## 5. Update viewer to use model layer

- [ ] 5.1 Update `queue.lisp`: remove `viewer-refresh` monkey-patch on `cl-occt.impl:propagate-changes`; rewrite `viewer-refresh` to iterate local `*model-registry*`
- [ ] 5.2 Update `display` in queue.lisp to also register a simple model in `*model-registry*`
- [ ] 5.3 Remove `undisplay` from queue.lisp
- [ ] 5.4 Update `ops.lisp`: remove local `resolve-shade`; update `def` to register in model registry + display grayed; update `show` to resolve from registry if not yet in `*displayed-models*`
- [ ] 5.5 Update `lifecycle.lisp`: register `viewer-refresh` on `*after-propagation-hook*` at startup
- [ ] 5.6 Update package exports: remove `resolve-shape` from old location, add model layer symbols to `:clotcad` and `:clotcad.impl` in `src/package.lisp`

## 6. Update ASDF system definition

- [ ] 6.1 Add `:module "model"` to `clotcad.asd` with all model files, positioned after `:module "package"` and before `:module "viewer"`
- [ ] 6.2 Update `:module "package"` path to `src/package.lisp`

## 7. Update documentation

- [ ] 7.1 Update `docs/clotcad-api.md` with new DSL/DAG API: `defmodel`, `param`, `with-params`, `model-ref`, `set-param!`, `set-params!`, `model-color`, `model-display-name`, `model-layer`, `*params*`, `*model-registry*`, `write-dag-models-to-step`, `read-step-into-dag`, `help`
- [ ] 7.2 Remove `undisplay` from docs
- [ ] 7.3 Update `docs/cheatsheet/cheatsheet.typ` with new DSL/DAG API entries

## 8. Tests

- [ ] 8.1 Add `model-registration` tests: register, find, unregister model
- [ ] 8.2 Add `param-resolution` tests: global params, local params, missing param error
- [ ] 8.3 Add `propagation` tests: dirty marking, topological sort, re-evaluation, cycle detection
- [ ] 8.4 Add `defmodel` tests: model definition, keyword function, metadata parsing, dependency tracking

## 9. Verify

- [ ] 9.1 Load `:clotcad` system in SBCL and confirm no package errors
- [ ] 9.2 Run `just test` to confirm all existing tests pass
- [ ] 9.3 Manual smoke test: `(def :b (make-box 10 20 30))` + `(show :b)` + `(hide :b)` + `(show :b)`
- [ ] 9.4 Manual smoke test: `(defmodel my-box (:w) (make-box (param :w) 20 30))` + `(set-param! :w 50)` + verify propagation
