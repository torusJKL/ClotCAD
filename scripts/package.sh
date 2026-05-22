#!/bin/bash
set -euo pipefail

ROOT_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"
DIST_DIR="$ROOT_DIR/dist"
VERSION="${VERSION:-$(git -C "$ROOT_DIR" describe --tags --dirty --always 2>/dev/null | sed 's/^v//' || echo "dev")}"

echo "==> Assembling distribution $VERSION"

# Clean previous artifacts
APPDIR="$ROOT_DIR/ClotCAD-$VERSION-x86_64.AppDir"
rm -rf "$DIST_DIR" "$APPDIR"
mkdir -p "$DIST_DIR"/{lib/occt,lib/qt6/plugins/platforms,sbcl/bin,share/licenses,share/icons,usr/share/applications,usr/share/icons/hicolor/256x256/apps}

# 1. SBCL core + runtime
echo "  → Core dump"
cd "$ROOT_DIR"
LD_LIBRARY_PATH=lib:.local/lib:lib/cl-occt/lib \
  sbcl --script scripts/make-core.lisp
mv ClotCAD.core "$DIST_DIR/"

echo "  → SBCL runtime"
SBCL_HOME="$(dirname "$(readlink -f "$(which sbcl)")")/.."
cp -L "$(which sbcl)" "$DIST_DIR/sbcl/bin/sbcl"
if [ -d "$SBCL_HOME/lib/sbcl" ]; then
  mkdir -p "$DIST_DIR/sbcl/lib"
  cp -r "$SBCL_HOME/lib/sbcl" "$DIST_DIR/sbcl/lib/"
fi

# 2. C++ libraries
echo "  → libocctviewer.so"
cp "$ROOT_DIR/lib/libocctviewer.so" "$DIST_DIR/lib/"

echo "  → libocctwrap.so"
cp "$ROOT_DIR/lib/cl-occt/lib/libocctwrap.so" "$DIST_DIR/lib/"

# 3. OCCT shared libraries
echo "  → OCCT libraries"
OCCT_LIBS=$(ldd "$DIST_DIR/lib/libocctviewer.so" "$DIST_DIR/lib/libocctwrap.so" 2>/dev/null \
  | grep -oP '/\S+libTK\w+\.so[.\d]*' | sort -u)
if [ -z "$OCCT_LIBS" ]; then
  # Fallback: copy all OCCT libs from .local
  cp "$ROOT_DIR"/.local/lib/libTK*.so* "$DIST_DIR/lib/occt/"
else
  while IFS= read -r lib; do
    cp -L "$lib" "$DIST_DIR/lib/occt/"
  done <<< "$OCCT_LIBS"
  # Also copy symlinks
  cp -a "$ROOT_DIR"/.local/lib/libTK*.so* "$DIST_DIR/lib/occt/" 2>/dev/null || true
fi

# 4. Qt6 shared libraries
echo "  → Qt6 libraries"
QT6_LIBS="libQt6Core.so.6 libQt6Gui.so.6 libQt6Widgets.so.6 libQt6OpenGL.so.6 libQt6OpenGLWidgets.so.6 libQt6DBus.so.6 libQt6XcbQpa.so.6"
QT_LIB_DIR="/usr/lib/x86_64-linux-gnu"
for lib in $QT6_LIBS; do
  found=$(find "$QT_LIB_DIR" -name "$lib" 2>/dev/null | head -1)
  if [ -z "$found" ]; then
    found=$(ldconfig -p 2>/dev/null | grep "$lib" | head -1 | awk '{print $NF}')
  fi
  if [ -n "$found" ]; then
    cp -L "$found" "$DIST_DIR/lib/qt6/"
  else
    echo "  WARNING: $lib not found"
  fi
done

# ICU libraries (transitive Qt6Core dependencies — version-agnostic)
ICU_LIBS="libicui18n libicuuc libicudata"
for lib in $ICU_LIBS; do
  found=$(find "$QT_LIB_DIR" -name "${lib}.so.*" 2>/dev/null | head -1)
  if [ -z "$found" ]; then
    found=$(ldconfig -p 2>/dev/null | grep -oP "/\S+${lib}\.so\.\d+" | head -1)
  fi
  if [ -n "$found" ]; then
    cp -L "$found" "$DIST_DIR/lib/qt6/"
  else
    echo "  WARNING: $lib not found"
  fi
done

# Qt6 platform plugin
echo "  → Qt6 platform plugin"
xcb_plugin=$(find "$QT_LIB_DIR" -path "*/plugins/platforms/libqxcb.so" 2>/dev/null | head -1)
if [ -z "$xcb_plugin" ]; then
  xcb_plugin=$(find /usr -path "*/plugins/platforms/libqxcb.so" 2>/dev/null | head -1)
fi
if [ -n "$xcb_plugin" ]; then
  cp -L "$xcb_plugin" "$DIST_DIR/lib/qt6/plugins/platforms/"
else
  echo "  WARNING: libqxcb.so not found"
fi

# 5. Licenses
echo "  → License files"
cp -r "$ROOT_DIR/share/licenses" "$DIST_DIR/share/"

# 6. Icon
PNG="$ROOT_DIR/share/icons/ClotCAD-logo.png"
echo "  → Icon"
cp "$PNG" "$DIST_DIR/ClotCAD.png"
cp "$PNG" "$DIST_DIR/.DirIcon"
cp "$PNG" "$DIST_DIR/usr/share/icons/hicolor/256x256/apps/ClotCAD.png"
cp "$ROOT_DIR/share/icons/ClotCAD-logo.svg" "$DIST_DIR/share/icons/"

# 7. Desktop file
echo "  → Desktop file"
cp "$ROOT_DIR/share/ClotCAD.desktop" "$DIST_DIR/"
cp "$ROOT_DIR/share/ClotCAD.desktop" "$DIST_DIR/usr/share/applications/"

# 8. Launcher
echo "  → Launcher"
cp "$ROOT_DIR/scripts/run.sh" "$DIST_DIR/AppRun"
chmod +x "$DIST_DIR/AppRun"

echo ""
echo "==> Distribution assembled at $DIST_DIR"
echo "    Contents:"
du -sh "$DIST_DIR"/*
echo ""

# Build tarball
TARBALL="$ROOT_DIR/ClotCAD-$VERSION-x86_64.tar.gz"
echo "==> Creating tarball: $TARBALL"
tar czf "$TARBALL" -C "$ROOT_DIR" dist/
echo "    Done: $(du -h "$TARBALL" | cut -f1)"

# Build AppImage (if tools available)
if command -v linuxdeploy &>/dev/null && command -v appimagetool &>/dev/null; then
  APPDIR="$ROOT_DIR/ClotCAD-$VERSION-x86_64.AppDir"
  APPIMAGE="$ROOT_DIR/ClotCAD-$VERSION-x86_64.AppImage"
  echo "==> Creating AppImage: $APPIMAGE"

  mv "$DIST_DIR" "$APPDIR"
  # Phase 1: deploy dependencies (creates symlinks)
  linuxdeploy --appdir "$APPDIR"
  # Remove any Qt/ICU libs linuxdeploy placed in usr/lib (we bundle our own)
  rm -f "$APPDIR"/usr/lib/libQt6*.so.* "$APPDIR"/usr/lib/libicu*.so.*
  # Replace symlinks with real files so appimagetool embeds the data
  rm -f "$APPDIR/ClotCAD.png" "$APPDIR/ClotCAD.desktop"
  cp "$ROOT_DIR/share/icons/ClotCAD-logo.png" "$APPDIR/ClotCAD.png"
  cp "$ROOT_DIR/share/ClotCAD.desktop" "$APPDIR/"
  # Phase 2: build AppImage
  appimagetool "$APPDIR" "$APPIMAGE"
  mv "$APPDIR" "$DIST_DIR"
  echo "    Done: $(du -h "$APPIMAGE" | cut -f1)"
else
  echo "==> Skipping AppImage (linuxdeploy/appimagetool not found)"
  echo "    Install from https://github.com/linuxdeploy/linuxdeploy"
  echo "    and https://github.com/AppImage/AppImageKit"
fi

echo ""
echo "==> All distribution artifacts created."
