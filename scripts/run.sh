#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/lib/occt:$HERE/lib:$HERE/usr/lib"
export QT_PLUGIN_PATH="$HERE/lib/plugins"

exec "$HERE/sbcl/bin/sbcl" --core "$HERE/ClotCAD.core" \
     --eval '(cl-occt-viewer:bootstrap)' \
     --eval '(sb-ext:quit)'
