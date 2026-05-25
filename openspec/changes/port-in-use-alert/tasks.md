## 1. C++ Dialog Function

- [x] 1.1 Add `viewer_show_message` declaration to `wrap/occt_viewer.h`
- [x] 1.2 Add `viewer_show_message` implementation in `wrap/occt_viewer.cpp` using `QMessageBox::warning`

## 2. Lisp CFFI Binding

- [x] 2.1 Add `%viewer-show-message` defcfun to `src/viewer/bindings.lisp`

## 3. Lisp Port Error Detection & Storage

- [x] 3.1 Add `*pending-port-errors*` variable to `src/viewer/lifecycle.lisp`
- [x] 3.2 Modify `start-slynk` to pre-check port via `sb-bsd-sockets:inet-socket` bind before spawning thread; if `address-in-use-error`, push to `*pending-port-errors*` and return nil
- [x] 3.3 Wrap the Slynk spawned thread body in `handler-case` catching `sb-bsd-sockets:address-in-use-error` as safety net against pre-check race
- [x] 3.4 Modify `start-alive` to pre-check port via `usocket:socket-listen` before calling `start-server` and push to `*pending-port-errors*` if in use

## 4. Lisp Dialog Display

- [x] 4.1 Modify `initialize-viewer` in `src/viewer/lifecycle.lisp` to iterate `*pending-port-errors*` and call `%viewer-show-message` for each

## 5. Testing

- [x] 5.1 Add `%viewer-show-message` to the mocked CFFI function list in the test suite's `with-mocked-viewer` macro
- [x] 5.2 Verify building: `just viewer` compiles cleanly
- [x] 5.3 Verify tests pass: `just test`
