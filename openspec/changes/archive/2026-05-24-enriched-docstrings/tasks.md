## 1. Convert `src/viewer/ui.lisp` docstrings

- [x] 1.1 Update `show-grid` docstring: `Example:` → `**Example:**`, `See also:` → `**See also:**`, add `**Returns:**` section, format params as `- **show**` bullets
- [x] 1.2 Update `show-axis` docstring: same conversion as 1.1
- [x] 1.3 Update `toggle-grid` docstring: same conversion, add `**Returns:**`
- [x] 1.4 Update `toggle-axis` docstring: same conversion, add `**Returns:**`
- [x] 1.5 Update `show-viewcube` docstring: same conversion
- [x] 1.6 Update `toggle-viewcube` docstring: same conversion
- [x] 1.7 Update `show-viewcube-axes` docstring: same conversion
- [x] 1.8 Update `toggle-viewcube-axes` docstring: same conversion
- [x] 1.9 Update `set-view` docstring: format `orientation` param as `- **orientation**`, add `**Returns:**`, convert example/section headers
- [x] 1.10 Update `current-view` docstring: add `**Returns:**`, convert headers
- [x] 1.11 Update `show-repl` docstring: same conversion
- [x] 1.12 Update `show-scene-tree` docstring: same conversion
- [x] 1.13 Update `toggle-repl` docstring: same conversion
- [x] 1.14 Update `toggle-scene-tree` docstring: same conversion
- [x] 1.15 Update `set-view-aa` docstring: format `enable` param, convert headers
- [x] 1.16 Update `fit-view` docstring: add `**Returns:**`, convert headers

## 2. Convert `src/viewer/ops.lisp` docstrings

- [x] 2.1 Update `def` macro docstring: convert to bold convention, format `name` and `shape-form` params as bullets
- [x] 2.2 Update `show` docstring: convert headers, format `&rest names` param
- [x] 2.3 Update `hide` docstring: same conversion
- [x] 2.4 Update `toggle` docstring: same conversion
- [x] 2.5 Update `show-defs` docstring: format `on` param, convert headers
- [x] 2.6 Update `toggle-defs` docstring: convert headers
- [x] 2.7 Update `cut` docstring: format `shape` and `&rest others` params, convert headers
- [x] 2.8 Update `fuse` docstring: same conversion
- [x] 2.9 Update `common` docstring: same conversion
- [x] 2.10 Update `section` docstring: same conversion
- [x] 2.11 Update `translate` docstring: format `shape`, `dx`, `dy`, `dz` params, convert headers
- [x] 2.12 Update `rotate` docstring: format params, convert headers
- [x] 2.13 Update `make-prism` docstring: format params, convert headers
- [x] 2.14 Update `make-revol` docstring: format params, convert headers
- [x] 2.15 Update `make-compound` docstring: format `shapes` param, convert headers
- [x] 2.16 Update `make-part` docstring: format `shape` and `&key` params, convert headers
- [x] 2.17 Update `write-step` docstring: format params, convert headers
- [x] 2.18 Update `write-stl` docstring: format params including key `deflection`, convert headers

## 3. Convert `src/viewer/select.lisp` docstrings

- [x] 3.1 Update `select` docstring: convert headers, format `&rest designators` param
- [x] 3.2 Update `deselect` docstring: same conversion
- [x] 3.3 Update `clear-selection` docstring: add `**Returns:**`, convert headers
- [x] 3.4 Update `selected-shapes` docstring: add `**Returns:**`, convert headers
- [x] 3.5 Update `apply-selection-schemes` docstring: format `&key` params (`click`, `ctrl-click`, `shift-click`), convert headers

## 4. Convert `src/viewer/repl.lisp` docstrings

- [x] 4.1 Update `cancel-import` docstring: add `**Returns:**`, convert headers
- [x] 4.2 Update `replay-speed` docstring: format `ms` param, convert headers
- [x] 4.3 Update `result-export` docstring: format `flag` param, convert headers
- [x] 4.4 Update `export-repl-history` docstring: format `path` param, convert headers
- [x] 4.5 Update `set-repl-history-key` docstring: format `modifier` param, convert headers
- [x] 4.6 Update `set-repl-submit-key` docstring: format `modifier` param, convert headers
- [x] 4.7 Add docstring to `log-remote-eval` with params `code-str`, `output-str`, example, returns

## 5. Verify `src/viewer/lifecycle.lisp` consistency

- [x] 5.1 Verify `start-viewer` uses `**Example:**` / `**See also:**` bold convention — add if missing
- [x] 5.2 Verify `bootstrap` uses bold convention — add if missing
- [x] 5.3 Verify `stop-viewer` uses bold convention — add if missing

## 6. Add missing `src/viewer/queue.lisp` docstrings

- [x] 6.1 Add docstring to `display` with params `name`, `shape`, `&key visible`, `show-in-tree`, `origin`; add example showing typical usage
- [x] 6.2 Add docstring to `clear-all` with example and `**Returns:**`

## 7. Add `src/model/api.lisp` docstrings

- [x] 7.1 Add docstring to `resolve-shape` with param `designator`, returns description, example
- [x] 7.2 Add docstring to `model-color` with param `name`, returns description, example
- [x] 7.3 Add docstring to `model-display-name` with param `name`, returns description, example
- [x] 7.4 Add docstring to `model-layer` with param `name`, returns description, example
- [x] 7.5 Add docstring to `model-ref` with param `name`, returns description, example
- [x] 7.6 Add docstring to `param` with param `key`, returns description, example
- [x] 7.7 Add docstring to `with-params` macro with `&rest bindings` and `&body body`, example showing typical usage
- [x] 7.8 Add docstring to `defmodel` macro with params `name`, `(&rest param-keys)`, `&body body`, example
- [x] 7.9 Add docstring to `set-param!` with params `key`, `value`, example
- [x] 7.10 Add docstring to `set-params!` with `&rest key-values`, example
- [x] 7.11 Add docstring to `write-dag-models-to-step` with param `path`, example
- [x] 7.12 Add docstring to `read-step-into-dag` with param `path`, example
- [x] 7.13 Add docstring to `help` with example showing `(help)` and `(help 'topic-name)`

## 8. Verify `src/viewer/theme.lisp` consistency

- [x] 8.1 Verify `apply-theme` uses bold convention — add if missing; ensure `**Returns:**` present
- [x] 8.2 Verify `set-accent` uses bold convention — add if missing
- [x] 8.3 Verify `theme-dark` uses bold convention — add if missing
- [x] 8.4 Verify `theme-light` uses bold convention — add if missing
- [x] 8.5 Verify `theme-auto` uses bold convention — add if missing
- [x] 8.6 Verify `set-font-size` uses bold convention — add if missing; ensure `**Returns:**` present

## 9. Final audit

- [x] 9.1 Verify every exported function in `:clotcad` package has a docstring
- [x] 9.2 Verify all `**Example:**` sections contain syntactically valid Common Lisp code
- [x] 9.3 Verify no `Example:` (non-bold) remains in any viewer file
- [x] 9.4 Verify no `See also:` (non-bold) remains in any viewer file
- [x] 9.5 Run `just test` to confirm no regressions
