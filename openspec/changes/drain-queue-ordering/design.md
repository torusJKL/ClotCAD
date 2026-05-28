## Context

`drain-queue` in `src/viewer/queue.lisp` processes queued messages by rotating
the `*viewer-queue*` list into a local `items` variable, then iterating in
list order (front to back). Messages are pushed to the front of the list
(LIFO), so iteration order is the reverse of insertion order.

This means that in a single drain cycle, a `:clear` message (pushed first) is
processed *after* a `:display` message (pushed second), even though `clear-all`
was called before `display` in the user's code. The `:clear` undoes the
`:display`, and the shape is gone by the time `sync-viewer` runs.

## Goals / Non-Goals

**Goals:**
- Messages are processed in FIFO (submission) order within a single drain cycle
- All existing API functions (`display`, `clear-all`, `remove`) continue to work
  unchanged

**Non-Goals:**
- No changes to the threading model or event posting mechanism
- No removal of the `:clear` message type (it becomes correct with FIFO)
- No changes to C++ event handling

## Decisions

**Decision: Reverse items after rotating from queue**

Insert `(setf items (nreverse items))` in `drain-queue` immediately after
`(rotatef items *viewer-queue*)`.

- Rationale: Minimal change — one line, no new data structures, no lock
  contention changes. The queue is already fully consumed by `rotatef`, so
  reversing the local `items` list is trivially safe.
- Alternative considered: Change the queue to a genuine FIFO structure (e.g.,
  append to tail, pop from head). This would require more refactoring across
  `queue-push` and `drain-queue` for no additional benefit.
- Alternative considered: Remove `:clear` message and let `sync-viewer` handle
  it. Also valid, but changes the contract of `clear-all` unnecessarily —
  with FIFO the `:clear` message is harmless.

## Risks / Trade-offs

- **Risk: Existing tests use single-message queues** → no existing test breaks
  because `nreverse` on a 1-element list is a no-op
- **Risk: Message order dependency** → some message pairs are naturally
  order-sensitive (`:remove` then `:display`, `:display` then `:remove`).
  FIFO is always the correct semantics for a queue — this is not a risk.
