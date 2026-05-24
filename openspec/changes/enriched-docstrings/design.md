## Context

The ClotCAD codebase currently has a split docstring convention. Viewer functions in `ui.lisp`, `ops.lisp`, `select.lisp`, and `repl.lisp` use a plain markdown style (`Example:`), while functions in `lifecycle.lisp` and `theme.lisp` use a bold-markers style (`**Example:**`) that matches the upstream `cl-occt` library. The entire model API layer (`src/model/api.lisp`) has no docstrings at all. Additionally, a few viewer functions (`display`, `clear-all`, `log-remote-eval`) lack docstrings.

The upstream `cl-occt` library provides the reference convention — all contributors familiar with `cl-occt` expect docstrings in that format.

## Goals / Non-Goals

**Goals:**
- All public functions in the `:clotcad` package have docstrings
- All docstrings follow a single, consistent format matching `cl-occt`
- Every docstring that describes an operation includes an executable example (unless it's a trivial predicate)
- Parameter documentation uses `- **name** description` bullet lists
- Return values are documented in `**Returns:**` sections

**Non-Goals:**
- Adding or changing any function behavior, signatures, or exports
- Documenting internal / non-exported functions
- Generating API reference docs in other formats (HTML, PDF, etc.)
- Modifying CFFI binding docstrings in `bindings.lisp`
- Variable docstrings, class docstrings, or struct docstrings

## Decisions

- **Adopt cl-occt convention exactly**: Bold markers for section headers (`**Example:**`, `**Returns:**`, `**See also:**`), backtick-quoted code references, `- **param**` bullet lists for parameters. This is the least-surprise choice for developers working across both libraries.

- **Add `**Returns:**` to every function**: Even for side-effect functions, document what (if anything) is returned. Many current docstrings describe return values inline; these should be extracted into a consistent `**Returns:**` section.

- **Examples use the `;; =>` result annotation** for non-trivial return values (e.g., `(make-box 10 20 30) ;; => #<SHAPE ...>`), matching the cl-occt pattern for clarity.

- **Model API functions receive full docstrings**: Despite being a new addition, they should follow the same convention as viewer functions. Where the semantics are clear from the name and context, a minimal but correct docstring is preferred over nothing.

- **No structural changes to code**: Docstrings are pure string literals — no macros, no defgeneric changes, no export list modifications.

## Risks / Trade-offs

- **Risk**: A docstring typo could cause a reader to misunderstand an API. → **Mitigation**: Each docstring follows a template pattern, reducing variability. Simple correctness check via `(describe 'function-name)` in the REPL.
- **Risk**: Inconsistency could re-emerge if new code doesn't follow convention. → **Mitigation**: This is an existing problem; the change improves it but doesn't solve it structurally. Consider adding a lint rule in the future.
- **Trade-off**: Examples in docstrings may drift from actual behavior if the API changes. → This is a pre-existing risk for all docstrings; no worse than current state.
