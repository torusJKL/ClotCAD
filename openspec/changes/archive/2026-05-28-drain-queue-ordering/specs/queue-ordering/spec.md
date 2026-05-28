## ADDED Requirements

### Requirement: FIFO message processing

`drain-queue` SHALL process viewer queue messages in the order they were
submitted (FIFO: first-in, first-out). A message submitted before another
message MUST be processed before that other message.

#### Scenario: clear-all then display within same eval

- **WHEN** a REPL evaluation calls `(clear-all)` then `(display :name shape)` 
- **THEN** the shape appears in the viewport after the queue is drained

#### Scenario: display then clear-all within same eval

- **WHEN** a REPL evaluation calls `(display :name shape)` then `(clear-all)`
- **THEN** no shape appears in the viewport after the queue is drained

#### Scenario: interleaved display and remove

- **WHEN** a REPL evaluation calls `(display :a shape-a)`, then `(display :b shape-b)`, then `(remove :a)`
- **THEN** after draining, only shape-b is present in `*displayed-models*`

#### Scenario: three-way ordering of clear, display, display

- **WHEN** a REPL evaluation calls `(clear-all)`, then `(display :x shape-x)`, then `(display :y shape-y)`
- **THEN** after draining, both shape-x and shape-y are present in `*displayed-models*`
