## ADDED Requirements

### Requirement: Selection state tracked in Lisp

The system SHALL maintain a global selection state `*selected*` as a hash table mapping shape name strings to `t`. This is the authoritative source of truth for what is selected.

#### Scenario: Initial state is empty

- **WHEN** the viewer starts
- **THEN** `*selected*` SHALL be an empty hash table

#### Scenario: select adds names

- **WHEN** `(select "box1" "box2")` is called
- **THEN** `*selected*` SHALL contain `"box1"` and `"box2"`
- **AND** `*selected*` SHALL contain no other keys

#### Scenario: select clears previous selection

- **WHEN** `*selected*` contains `"box1"` and `(select "box2")` is called
- **THEN** `*selected*` SHALL contain only `"box2"`

### Requirement: REPL selection commands

The system SHALL provide `select`, `deselect`, `clear-selection`, and `selected-shapes` commands usable from the REPL.

#### Scenario: select with symbols

- **WHEN** `(select :box1 :box2)` is called
- **THEN** `(selected-shapes)` SHALL return `'("BOX1" "BOX2")`

#### Scenario: deselect removes specific shapes

- **WHEN** `*selected*` contains `"box1"` and `"box2"`, and `(deselect "box1")` is called
- **THEN** `*selected*` SHALL contain only `"box2"`

#### Scenario: clear-selection empties

- **WHEN** `*selected*` is non-empty and `(clear-selection)` is called
- **THEN** `(selected-shapes)` SHALL return `'()`

#### Scenario: select with empty args does nothing

- **WHEN** `(select)` is called
- **THEN** `*selected*` SHALL be empty

### Requirement: Selection synced to OCCT context on main thread

When `(select ...)`, `(deselect ...)`, or `(clear-selection)` is called from the REPL (worker thread), the system SHALL push a `:sync-selection` message to the viewer queue and post a wake event. The drain handler on the main thread SHALL call `ais-clear-selected`, `ais-set-selected` for each entry in `*selected*`, then `ais-hilight-selected`.

#### Scenario: select from REPL syncs to OCCT

- **WHEN** `(select "box1")` is called from the REPL
- **THEN** `*selected*` SHALL be updated immediately
- **AND** a `:sync-selection` message SHALL be pushed to the queue
- **AND** when the drain handler runs, `ais-clear-selected` SHALL be called with `:update nil`
- **AND** `ais-set-selected` SHALL be called for `"box1"`
- **AND** `ais-hilight-selected` SHALL be called with `:update t`

#### Scenario: deselect from REPL syncs to OCCT

- **WHEN** `(deselect "box1")` is called from the REPL
- **THEN** `*selected*` SHALL be updated immediately
- **AND** a `:sync-selection` message SHALL be pushed

### Requirement: Shared sync helper

The system SHALL provide a `sync-selection-to-occt` function that reads `*selected*` and calls the cl-occt selection API. This SHALL be callable from both the queue drain handler and main-thread callbacks.

#### Scenario: sync-selection-to-occt clears OCCT and sets each selected shape

- **WHEN** `sync-selection-to-occt` is called with `*viewer*` bound
- **THEN** `%viewer-get-context` SHALL be called to obtain the context
- **AND** `ais-clear-selected` SHALL be called
- **AND** For each entry in `*selected*`, `%viewer-get-ais-object` SHALL be called to look up the handle
- **AND** If the handle is non-null, `ais-set-selected` SHALL be called
- **AND** `ais-hilight-selected` SHALL be called

### Requirement: Selection scheme configurable from Lisp

The system SHALL provide `apply-selection-schemes` with keyword arguments `:click`, `:ctrl-click`, and `:shift-click`, accepting `:replace`, `:add`, `:remove`, `:xor`, `:clear`, or `:replace-extra`. The function SHALL push the scheme values to the C layer via `%viewer-set-mouse-selection-scheme`.

#### Scenario: default scheme is ReplaceExtra

- **WHEN** `apply-selection-schemes` is called with no arguments
- **THEN** the C layer SHALL be configured with `:replace-extra` for click, `:add` for Ctrl+click, `:xor` for Shift+click

#### Scenario: custom scheme is applied

- **WHEN** `(apply-selection-schemes :click :add :ctrl-click :xor)` is called
- **THEN** click SHALL add to selection, Ctrl+click SHALL toggle
