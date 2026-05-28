## 1. FIFO ordering fix

- [x] 1.1 Add `(setf items (nreverse items))` in `drain-queue` after rotating the queue

## 2. Tests

- [x] 2.1 Add test: `clear-all` then `display` within same drain — shape present after drain
- [x] 2.2 Add test: `display` then `clear-all` within same drain — no shapes after drain
- [x] 2.3 Add test: interleaved `display`, `display`, `remove` within same drain — correct final set
- [x] 2.4 Add test: `clear-all`, `display`, `display` within same drain — both shapes present after drain
- [x] 2.5 Verify all existing tests still pass with `just test`
