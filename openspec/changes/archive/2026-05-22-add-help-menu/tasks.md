## 1. Qt Resource Setup

- [x] 1.1 Create `wrap/resources.qrc` referencing `../share/icons/ClotCAD-logo.svg` with alias `:/icons/ClotCAD-logo.svg`
- [x] 1.2 Add `qt6_add_resources(occtviewer "resources" wrap/resources.qrc)` to `CMakeLists.txt`

## 2. Help Menu Declaration

- [x] 2.1 Add `QAction* myAboutAction` member to `ViewerWindow` in `viewer_window.h`
- [x] 2.2 Add `QAction* aboutAction() const { return myAboutAction; }` accessor to `viewer_window.h`

## 3. Help Menu Creation

- [x] 3.1 Add Help `QMenu* helpMenu = mb->addMenu(tr("&Help"))` in `setupMenus()` in `viewer_window.cpp`
- [x] 3.2 Add `myAboutAction = helpMenu->addAction(tr("&About ClotCAD"))` in `setupMenus()`

## 4. About Dialog Implementation

- [x] 4.1 Add `#include <QDialog>`, `#include <QVBoxLayout>`, `#include <QLabel>`, `#include <QDialogButtonBox>`, `#include <QPushButton>` to `occt_viewer.cpp`
- [x] 4.2 Add `showAboutDialog()` free function in `occt_viewer.cpp` that creates a modal QDialog with:
       - SVG logo via `QLabel` + `QPixmap(":/icons/ClotCAD-logo.svg")`
       - App name "ClotCAD" as a heading label
       - Short description paragraph
       - Clickable links (ClotCAD repo, OCCT, Qt, SBCL, etc.) via `QLabel` with `setOpenExternalLinks(true)`
       - `QDialogButtonBox::Close` for dismissal

## 5. Action Wiring

- [x] 5.1 Connect `win->aboutAction()` to `showAboutDialog()` lambda in `viewer_create()` in `occt_viewer.cpp`
