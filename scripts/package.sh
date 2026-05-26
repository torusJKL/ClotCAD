#!/bin/bash
set -euo pipefail

ROOT_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"
DIST_DIR="$ROOT_DIR/dist"
VERSION="${VERSION:-$(git -C "$ROOT_DIR" describe --tags --dirty --always 2>/dev/null | sed 's/^v//' || echo "dev")}"

echo "==> Assembling distribution $VERSION"

# Clean previous artifacts
APPDIR="$ROOT_DIR/ClotCAD-$VERSION-x86_64.AppDir"
rm -rf "$DIST_DIR" "$APPDIR"
mkdir -p "$DIST_DIR"/{lib/occt,lib/plugins/platforms,sbcl/bin,share/licenses,share/icons,usr/share/applications,usr/share/icons/hicolor/256x256/apps}

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
  # Remove unused contrib modules to save space
  rm -f "$DIST_DIR/sbcl/lib/sbcl/contrib/sb-simd.fasl" \
        "$DIST_DIR/sbcl/lib/sbcl/contrib/sb-simd.asd" \
        "$DIST_DIR/sbcl/lib/sbcl/contrib/sb-mpfr.fasl" \
        "$DIST_DIR/sbcl/lib/sbcl/contrib/sb-mpfr.asd" \
        "$DIST_DIR/sbcl/lib/sbcl/contrib/sb-gmp.fasl" \
        "$DIST_DIR/sbcl/lib/sbcl/contrib/sb-gmp.asd"
  # Remove sbcl.o object file (not needed at runtime)
  rm -f "$DIST_DIR/sbcl/lib/sbcl/sbcl.o"
fi

# 2. C++ libraries
echo "  → libclotcad.so"
cp "$ROOT_DIR/lib/libclotcad.so" "$DIST_DIR/lib/"

echo "  → libocctwrap.so"
cp "$ROOT_DIR/lib/cl-occt/lib/libocctwrap.so" "$DIST_DIR/lib/"

# 3. OCCT shared libraries
echo "  → OCCT libraries"
OCCT_LIBS=$(LD_LIBRARY_PATH= ldd "$DIST_DIR/lib/libclotcad.so" "$DIST_DIR/lib/libocctwrap.so" 2>/dev/null \
  | grep -oP '/\S+libTK\w+\.so[.\d]*' | sort -u || true)
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

# 4. Qt6 libraries needed by plugins (linuxdeploy handles the rest)
echo "  → Qt6 libraries"
QT6_PLUGIN_LIBS="libQt6Core.so.6 libQt6Gui.so.6 libQt6Widgets.so.6 libQt6OpenGL.so.6 libQt6OpenGLWidgets.so.6 libQt6DBus.so.6 libQt6XcbQpa.so.6 libQt6WaylandClient.so.6"
QT_LIB_DIR="/usr/lib/x86_64-linux-gnu"
for lib in $QT6_PLUGIN_LIBS; do
  found=$(find "$QT_LIB_DIR" -name "$lib" 2>/dev/null | head -1 || true)
  if [ -z "$found" ]; then
    found=$(ldconfig -p 2>/dev/null | grep "$lib" | head -1 | awk '{print $NF}' || true)
  fi
  if [ -n "$found" ]; then
    cp -L "$found" "$DIST_DIR/lib/"
  else
    echo "  WARNING: $lib not found"
  fi
done

# ICU libraries — resolve exact SONAMEs from Qt6Core's NEEDED entries
echo "  → ICU libraries"
qt6core="$DIST_DIR/lib/libQt6Core.so.6"
if [ -f "$qt6core" ]; then
  ICU_LIBS=$(readelf -d "$qt6core" 2>/dev/null | grep -oP 'libicu\w+\.so\.\d+' || true)
  for lib in $ICU_LIBS; do
    found=$(find "$QT_LIB_DIR" -name "$lib" 2>/dev/null | head -1 || true)
    [ -z "$found" ] && found=$(ldconfig -p 2>/dev/null | grep " $lib " | head -1 | awk '{print $NF}' || true)
    if [ -n "$found" ]; then
      cp -L "$found" "$DIST_DIR/lib/"
      # Check for transitive ICU deps
      trans=$(readelf -d "$found" 2>/dev/null | grep -oP 'libicu\w+\.so\.\d+' || true)
      for t in $trans; do
        [ -f "$DIST_DIR/lib/$t" ] && continue
        tf=$(find "$QT_LIB_DIR" -name "$t" 2>/dev/null | head -1 || true)
        [ -z "$tf" ] && tf=$(ldconfig -p 2>/dev/null | grep " $t " | head -1 | awk '{print $NF}' || true)
        [ -n "$tf" ] && cp -L "$tf" "$DIST_DIR/lib/"
      done
    else
      echo "  WARNING: $lib not found"
    fi
  done
fi

# Qt6 platform plugins
echo "  → Qt6 platform plugins"
for plugin in libqxcb.so libqwayland.so; do
  found=$(find "$QT_LIB_DIR/qt6" -name "$plugin" -path "*/plugins/platforms/*" 2>/dev/null | head -1 || true)
  if [ -z "$found" ]; then
    found=$(find /usr/lib /usr -name "$plugin" -path "*/qt6/*/platforms/*" 2>/dev/null | head -1 || true)
  fi
  if [ -n "$found" ]; then
    cp -L "$found" "$DIST_DIR/lib/plugins/platforms/"
  else
    echo "  WARNING: $plugin not found"
  fi
done

# xcbglintegrations plugins (required for OpenGL/GLX/EGL contexts)
echo "  → xcbglintegrations plugins"
for plugin in libqxcb-glx-integration.so libqxcb-egl-integration.so; do
  found=$(find "$QT_LIB_DIR/qt6" -name "$plugin" -path "*/xcbglintegrations/*" 2>/dev/null | head -1 || true)
  if [ -z "$found" ]; then
    found=$(find /usr/lib /usr -name "$plugin" -path "*/qt6/*/xcbglintegrations/*" 2>/dev/null | head -1 || true)
  fi
  if [ -n "$found" ]; then
    mkdir -p "$DIST_DIR/lib/plugins/xcbglintegrations"
    cp -L "$found" "$DIST_DIR/lib/plugins/xcbglintegrations/"
  else
    echo "  WARNING: $plugin not found"
  fi
done

# Wayland shell integration plugins
echo "  → Wayland shell integration plugins"
for plugin in libqt-shell.so libivi-shell.so; do
  found=$(find "$QT_LIB_DIR/qt6" -name "$plugin" -path "*/wayland-shell-integration/*" 2>/dev/null | head -1 || true)
  if [ -z "$found" ]; then
    found=$(find /usr/lib /usr -name "$plugin" -path "*/qt6/*/wayland-shell-integration/*" 2>/dev/null | head -1 || true)
  fi
  if [ -n "$found" ]; then
    mkdir -p "$DIST_DIR/lib/plugins/wayland-shell-integration"
    cp -L "$found" "$DIST_DIR/lib/plugins/wayland-shell-integration/"
  fi
done

# Wayland graphics integration client plugins
echo "  → Wayland graphics integration plugins"
for dir in wayland-graphics-integration-client; do
  for f in /usr/lib/x86_64-linux-gnu/qt6/plugins/$dir/*.so; do
    [ -f "$f" ] && mkdir -p "$DIST_DIR/lib/plugins/$dir" && cp -L "$f" "$DIST_DIR/lib/plugins/$dir/"
  done 2>/dev/null || true
done

# ICU libraries will be handled by linuxdeploy when it analyzes Qt6 libraries

# qt.conf — override Qt6's compiled-in plugin path to use our bundled plugins
echo "  → qt.conf"
cat > "$DIST_DIR/lib/qt.conf" << 'EOF'
[Paths]
Prefix = ..
Plugins = lib/plugins
EOF
# Also place in application directory (Qt6 searches there first)
cat > "$DIST_DIR/sbcl/bin/qt.conf" << 'EOF'
[Paths]
Prefix = ../../..
Plugins = lib/plugins
EOF

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
  # Pass --library for key binaries so linuxdeploy resolves their deps (GLX, EGL, etc.)
  # Set LD_LIBRARY_PATH so linuxdeploy can find OCCT libs in lib/occt/
  LINUXDEPLOY_LIB_ARGS=()
  for lib in "$APPDIR/lib/libclotcad.so" "$APPDIR/lib/libocctwrap.so"; do
    [ -f "$lib" ] && LINUXDEPLOY_LIB_ARGS+=(--library "$lib")
  done
  LD_LIBRARY_PATH="$APPDIR/lib/occt:$APPDIR/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
    linuxdeploy --appdir "$APPDIR" --desktop-file "$APPDIR/ClotCAD.desktop" \
    --exclude-library="libxkbcommon" \
    --exclude-library="libxkbcommon-x11" \
    --exclude-library="libTK" \
    "${LINUXDEPLOY_LIB_ARGS[@]}"
  # Remove bundled libxkbcommon to avoid version conflicts with system libraries
  rm -f "$APPDIR/usr/lib/libxkbcommon.so.0" "$APPDIR/usr/lib/libxkbcommon-x11.so.0"
  # Remove duplicate OCCT libraries from usr/lib/ (already in lib/occt/)
  rm -f "$APPDIR/usr/lib/libTK"*.so*
  # Remove any Qt/ICU libs linuxdeploy placed in usr/lib (we bundle our own)
  rm -f "$APPDIR"/usr/lib/libQt6*.so.* "$APPDIR"/usr/lib/libicu*.so.*
  # Remove documentation to save space
  rm -rf "$APPDIR/usr/share/doc"
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
