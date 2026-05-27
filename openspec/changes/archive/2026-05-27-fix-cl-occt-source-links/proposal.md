## Why

Staple-generated documentation links to source code using GitHub URLs. For functions in the main ClotCAD repo, the links work correctly. But for functions from the `cl-occt` submodule (at `lib/cl-occt/`), the links point to `ClotCAD/blob/<sha>/lib/cl-occt/src/foo.lisp` — which shows a gitlink (submodule pointer), not the actual source. The links need to point to the `cl-occt` repository instead.

## What Changes

- Override `staple:resolve-source-link` in `homepage/setup.lisp` to detect source files under `lib/cl-occt/` and redirect their URLs to the `cl-occt` GitHub repository at the pinned submodule commit
- No changes to CI, justfile, templates, or other systems

## Capabilities

### New Capabilities

- `source-links`: Source link generation for documentation, handling multi-repository URL routing

### Modified Capabilities

_(none)_

## Impact

- Only `homepage/setup.lisp` modified
- No new dependencies
- No CI changes needed — `git rev-parse` works in both local and CI environments
