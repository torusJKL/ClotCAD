## Why

`drain-queue` processes queued viewer messages in LIFO (stack) order because
messages are pushed to the front and iterated from front to back. This causes
a bug where `(clear-all)` followed by `(display :name shape)` in the same REPL
eval results in the shape never appearing — the `:clear` message is processed
*after* the `:display` message, clearing the entry before it can be synced.

## What Changes

- `drain-queue` in `src/viewer/queue.lisp` processes messages in FIFO order
  instead of LIFO order, so messages are executed in the sequence they were sent
- No API changes — `display`, `clear-all`, `remove`, `queue-push`, etc. are
  unaffected at the call site

## Capabilities

### New Capabilities

- `queue-ordering`: Guarantees that viewer queue messages are processed in the
  order they were submitted (FIFO). This is an internal behavioral contract —
  no new user-facing API.

### Modified Capabilities

*(none — this is a behavioral fix, not a spec-level requirement change)*

## Impact

- **`src/viewer/queue.lisp`**: One-line change in `drain-queue` to reverse
  message order before processing
- **`t/viewer-tests.lisp`**: New tests verifying FIFO ordering of multiple
  message types in a single drain cycle
