# apropos-categories Specification

## Purpose
TBD - created by archiving change update-apropos-categories. Update Purpose after archive.
## Requirements
### Requirement: Category merge groups consolidate stems under one category

The system SHALL support a `*category-merge-groups*` parameter that defines which source-file stems should have their function lists merged into a target stem. Multiple source stems SHALL be combinable under a single target stem to avoid category tree bloat.

The merge SHALL happen during index building, after the initial `do-external-symbols` scan and before the index is cached. For each merge group, the function lists of all member stems SHALL be unioned into the target stem's entry, and the member stems SHALL be removed from the index.

Any stem not listed in any merge group SHALL continue to appear as an independent category (as before).

#### Scenario: Category tree shows merged functions under target name
- **WHEN** `*category-merge-groups*` includes `(:booleans :bop-splitter :bop-utilities :bop-volume)`
- **AND** the user calls `(apropos)`
- **THEN** functions from `bop-splitter.lisp`, `bop-utilities.lisp`, and `bop-volume.lisp` SHALL appear under the "Booleans" category entry
- **AND** no separate "BOP Splitter", "BOP Utilities", or "BOP Volume" categories SHALL appear

#### Scenario: Unmerged stems remain independent
- **WHEN** `animation.lisp` has exported functions but is not in any merge group
- **THEN** `(apropos)` SHALL display "Animation" as a standalone category with its own function list

#### Scenario: Merged functions still findable via substring search
- **WHEN** the user calls `(apropos "bop")`
- **THEN** all functions from merged BOP stems SHALL still appear in the substring search results, regardless of their merged category

#### Scenario: Merge groups configurable without code changes to core logic
- **WHEN** a new merge group is added to `*category-merge-groups*`
- **AND** the user rebuilds the category index via `%rebuild-category-index`
- **THEN** the next `(apropos)` call SHALL reflect the new grouping without any changes to the scanning or printing logic

