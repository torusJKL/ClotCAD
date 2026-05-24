## Why

The ClotCAD codebase has inconsistent and incomplete docstrings across its public API. Viewer functions use a mix of two formatting styles (with and without bold markers), several viewer functions lack docstrings entirely, and the entire model API layer (13 exported functions) has no docstrings at all. This makes the library harder to use from the REPL and for new contributors. Bringing all public functions to a single, enriched markdown convention — matching the upstream `cl-occt` library — improves discoverability, documentation quality, and consistency.

## What Changes

- Convert all viewer function docstrings to use the `cl-occt` convention (`**Example:**`, `**Returns:**`, `**See also:**` with bold markers, backtick-quoted code references, and `- **param**` bullet lists)
- Add docstrings with examples to all viewer public functions currently missing them (`log-remote-eval`, `display`, `clear-all`)
- Add docstrings with examples to all model API public functions currently missing them (all 13 exported functions in `src/model/api.lisp`)
- Add `**Returns:**` sections to functions that describe return values inline
- Add examples to any existing docstrings that lack them (except trivial predicates like `shape-p`)
- Standardize parameter documentation format to `- **name** description` bullets

## Capabilities

### New Capabilities

- `viewer-api-docs`: Enriched docstrings for all public functions exported from the `:clotcad` viewer package (`src/viewer/`). Covers `ui.lisp`, `ops.lisp`, `select.lisp`, `repl.lisp`, `lifecycle.lisp`, `theme.lisp`.
- `model-api-docs`: New docstrings for all public functions exported from the `:clotcad` model package (`src/model/`). Covers `api.lisp`.

### Modified Capabilities

None — no existing specs to modify.

## Impact

- **Source files touched**: `src/viewer/ui.lisp`, `src/viewer/ops.lisp`, `src/viewer/select.lisp`, `src/viewer/repl.lisp`, `src/viewer/lifecycle.lisp`, `src/viewer/theme.lisp`, `src/viewer/queue.lisp`, `src/model/api.lisp`
- **API surface**: No functional changes — docstrings only
- **Dependencies**: None
- **Tests**: No new tests needed (docstrings are non-functional)
