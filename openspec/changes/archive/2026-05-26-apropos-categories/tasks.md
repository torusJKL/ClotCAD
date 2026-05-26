## 1. Category infrastructure

- [x] 1.1 Add `sb-introspect` require and build the category-function index by introspecting all exported functions from `:cl-occt` and `:clotcad`
- [x] 1.2 Define `*category-display-names*` — the filename-stem-to-display-name mapping covering all cl-occt core source files
- [x] 1.3 Implement the lazy caching mechanism for the category index so introspection happens once per session
- [x] 1.4 Handle the case where `sb-introspect` is not available (graceful degradation to old behavior)

## 2. Core apropos rewrite

- [x] 2.1 Implement `%coerce-packages` utility that accepts a single designator, a list, or t
- [x] 2.2 Implement `%find-categories` — keyword to category matching with partial case-insensitive search against display names and filename stems
- [x] 2.3 Implement `%print-category-tree` — formats the no-argument `(apropos)` output (categories with counts and representative fn names)
- [x] 2.4 Implement `%print-category-detail` — formats the `(apropos :fillet)` output (all fns in a category with signatures and docstrings)
- [x] 2.5 Modify `apropos-impl` to handle three dispatch modes: no-pattern → category tree, keyword → category lookup, string/symbol → substring search
- [x] 2.6 Modify the `apropos` macro to make `pattern` optional and preserve existing quoting behavior

## 3. Edge cases and polish

- [x] 3.1 Handle multiple categories matching a keyword (show filtered tree of matches)
- [x] 3.2 Handle keyword matching no category (print "No category found", return nil)
- [x] 3.3 Ensure the `:packages` filter works correctly with category tree and category detail display
- [x] 3.4 Ensure the `:case-insensitive` flag still works for substring search mode

## 4. Tests

- [x] 4.1 Add unit tests for `%coerce-packages` with single, list, t, and nil inputs
- [x] 4.2 Add unit tests for `%find-categories` with exact match, partial match, and no match
- [x] 4.3 Add unit tests for category tree output (no-argument apropos)
- [x] 4.4 Add unit tests for category detail output (keyword apropos)
- [x] 4.5 Add unit tests for substring search still works with strings and bare symbols

## 5. Documentation

- [x] 5.1 Update `docs/clotcad-api.md` with the new `apropos` usage (no-arg tree, keyword lookup, single-designator :packages)
