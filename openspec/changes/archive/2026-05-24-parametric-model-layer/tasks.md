## 1. Package refactoring

- [x] 1.1 Move all three `defpackage` forms from `src/viewer/package.lisp` to new `src/package.lisp`
- [x] 1.2 Update `clotcad.asd` to load `:module "package"` (from `src/package.lisp`) before model and viewer modules
- [x] 1.3 Update `src/viewer/package.lisp` to use `in-package` only (no defpackage)

## 2. Model layer — core data structures

- [x] 2.1 Create `src/model/package.lisp` with `in-package` forms
- [x] 2.2 Create `src/model/model.lisp` with `model` struct (name, fn, param-keys, model-deps, dependents, dirty, cached-shape, last-param-hash, color, display-name, layer), `*model-registry*` hash table, `register-model`, `find-model`, `unregister-model`
- [x] 2.3 Create `src/model/params.lisp` with `*params*`, `*after-propagation-hook*`

## 3. Model layer — propagation

- [x] 3.1 Create `src/model/propagation.lisp` with `dirty-model!` (marks model + dependents dirty recursively)
- [x] 3.2 Implement `topological-sort` with cycle detection
- [x] 3.3 Implement `evaluate-model` (checks dirty flag and param hash, re-evaluates if needed)
- [x] 3.4 Implement `propagate-changes` (collect dirty models, topo-sort, evaluate each, fire `*after-propagation-hook*`)

## 4. Model layer — API

- [x] 4.1 Create `src/model/api.lisp`
- [x] 4.2 Implement `resolve-shape` (symbol/string/shape → cached shape from registry)
- [x] 4.3 Implement `param` (reads from `*local-params*` or `*params*`)
- [x] 4.4 Implement `with-params` macro
- [x] 4.5 Implement `defmodel` macro (parse metadata clauses, collect model-ref deps, detect param keys, register model, generate keyword function)
- [x] 4.6 Implement `model-ref`, `model-color`, `model-display-name`, `model-layer`
- [x] 4.7 Implement `set-param!` and `set-params!`
- [x] 4.8 Implement `write-dag-models-to-step` and `read-step-into-dag`
- [x] 4.9 Implement `help`

## 5. Update viewer to use model layer

- [x] 5.1 Update `queue.lisp`: remove `viewer-refresh` monkey-patch on `cl-occt.impl:propagate-changes`; rewrite `viewer-refresh` to iterate local `*model-registry*`
- [x] 5.2 Update `display` in queue.lisp to also register a simple model in `*model-registry*`
- [x] 5.3 Remove `undisplay` from queue.lisp
- [x] 5.4 Update `ops.lisp`: remove local `resolve-shade`; update `def` to register in model registry + display grayed; update `show` to resolve from registry if not yet in `*displayed-models*`
- [x] 5.5 Update `lifecycle.lisp`: register `viewer-refresh` on `*after-propagation-hook*` at startup
- [x] 5.6 Update package exports: remove `resolve-shape` from old location, add model layer symbols to `:clotcad` and `:clotcad.impl` in `src/package.lisp`

## 6. Update ASDF system definition

- [x] 6.1 Add `:module "model"` to `clotcad.asd` with all model files, positioned after `:module "package"` and before `:module "viewer"`
- [x] 6.2 Update `:module "package"` path to `src/package.lisp`

## 7. Update documentation

- [x] 7.1 Update `docs/clotcad-api.md` with new DSL/DAG API: `defmodel`, `param`, `with-params`, `model-ref`, `set-param!`, `set-params!`, `model-color`, `model-display-name`, `model-layer`, `*params*`, `*model-registry*`, `write-dag-models-to-step`, `read-step-into-dag`, `help`
- [x] 7.2 Remove `undisplay` from docs
- [x] 7.3 Update `docs/cheatsheet/cheatsheet.typ` with new DSL/DAG API entries

## 8. Tests

- [x] 8.1 Add `model-registration` tests: register, find, unregister model
- [x] 8.2 Add `param-resolution` tests: global params, local params, missing param error
- [x] 8.3 Add `propagation` tests: dirty marking, topological sort, re-evaluation, cycle detection
- [x] 8.4 Add `defmodel` tests: model definition, keyword function, metadata parsing, dependency tracking

## 9. Verify

- [x] 9.1 Load `:clotcad` system in SBCL and confirm no package errors (compilation succeeds)
- [x] 9.2 Run `just test` to confirm all existing tests pass — **134/134 pass, 0 failures**
- [x] 9.3 Manual smoke test: `(def :b (make-box 10 20 30))` + `(show :b)` + `(hide :b)` + `(show :b)`
- [x] 9.4 Manual smoke test: `(defmodel my-box (:w) (make-box (param :w) 20 30))` + `(set-param! :w 50)` + verify propagation
