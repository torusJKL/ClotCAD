## 1. Add DontUseNativeDialog to file dialogs

- [x] 1.1 Add `dialog.setOption(QFileDialog::DontUseNativeDialog)` to the Import STEP dialog in `wrap/occt_viewer.cpp`
- [x] 1.2 Add `dialog.setOption(QFileDialog::DontUseNativeDialog)` to the Import STL dialog
- [x] 1.3 Add `dialog.setOption(QFileDialog::DontUseNativeDialog)` to the Export STEP dialog
- [x] 1.4 Add `dialog.setOption(QFileDialog::DontUseNativeDialog)` to the Export STL dialog

## 2. Verify

- [x] 2.1 Build the project with `just viewer` and confirm no compilation errors
- [x] 2.2 Launch the viewer with `just start` and test each import/export dialog opens correctly
