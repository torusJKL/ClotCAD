## 1. Core Infrastructure: Merge-Group Mechanism

- [x] 1.1 Add `*category-merge-groups*` parameter to `src/viewer/introspect.lisp` with 14 group definitions (8 merged targets + 6 existing targets with new members)
- [x] 1.2 Modify `%build-category-index` to apply merge groups after the sort step: union function lists from source stems into target stem, `remhash` source stems
- [x] 1.3 Verify the merge runs before the index is cached in `*category-fn-index*`

## 2. Display Names for New Categories

- [x] 2.1 Add 8 new entries to `*category-display-names*` for merged-group targets:
  - `:graphic3d` → "Graphic3D", `:ocaf` → "OCAF", `:xcaf` → "XCAF",
    `:shape-utilities` → "Shape Utilities", `:advanced-modeling` → "Advanced Modeling",
    `:materials-texture` → "Materials & Texture", `:meshing` → "Meshing",
    `:2d-constraints` → "2D Constraints"
- [x] 2.2 Add 4 standalone entries: `:animation` → "Animation", `:normal-project` → "Normal Projection",
     `:transfer-params` → "Transfer Parameters", `:selection` → "Selection (OCCT)"

## 3. Tests

- [x] 3.1 Add test verifying that merge groups consolidate functions from multiple stems under the target category
- [x] 3.2 Add test verifying that unmerged stems remain as independent categories
- [x] 3.3 Add test verifying that merged functions still appear in substring search results
- [x] 3.4 Add test verifying `%rebuild-category-index` + merge groups works correctly
- [x] 3.5 Run `just test` to confirm all existing tests still pass
