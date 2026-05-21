## Why

`resolve-shape` only accepts symbols and raw shape objects, but `display` stores models under string keys in `*displayed-models*`. This means shapes defined with string names (e.g., `(def "box2" ...)`) cannot be referenced in boolean operations like `(cut :s "box2")`, forcing users to use symbols everywhere despite the code already supporting string keys internally.

## What Changes

- Add a `string` branch to `resolve-shape` in `src/viewer/ops.lisp` that does a direct `gethash` lookup in `*displayed-models*`
- Add tests for string resolution in `t/viewer-tests.lisp`
- Update README to document string support in resolve-shape

## Capabilities

### New Capabilities
- `resolve-shape-string`: Support string designators in `resolve-shape`, enabling shape operations on models registered by string name

### Modified Capabilities

None.

## Impact

- `src/viewer/ops.lisp`: One new etypecase branch in `resolve-shape`
- `t/viewer-tests.lisp`: Two new test cases (passes through string lookup, errors on unknown string)
- README: brief documentation update
