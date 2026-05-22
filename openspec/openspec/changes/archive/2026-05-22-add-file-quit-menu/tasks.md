## 1. Add QAction member to ViewerWindow

- [x] 1.1 Add `QAction* myQuitAction = nullptr;` member to `wrap/viewer_window.h` after `myAboutAction`
- [x] 1.2 Add `QAction* quitAction() const { return myQuitAction; }` accessor to `wrap/viewer_window.h` after the `aboutAction()` accessor

## 2. Add menu item in setupMenus()

- [x] 2.1 In `wrap/viewer_window.cpp` `setupMenus()`, add a separator after the Export REPL History action
- [x] 2.2 Add `myQuitAction = fileMenu->addAction(tr("&Quit"));` after the separator
- [x] 2.3 Set keyboard shortcut: `myQuitAction->setShortcut(QKeySequence("Ctrl+Q"));`

## 3. Wire signal in viewer_create()

- [x] 3.1 In `wrap/occt_viewer.cpp` `viewer_create()`, add `QObject::connect` to trigger `win->close()` when `quitAction` emits `triggered`

## 4. Build and verify

- [x] 4.1 Run `just viewer` to rebuild `lib/libocctviewer.so`
- [x] 4.2 Verify build succeeds with no errors
