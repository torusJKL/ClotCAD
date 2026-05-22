#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/lib/qt6:$HERE/lib/qt6/plugins:$HERE/lib/occt:$HERE/lib"

exec "$HERE/sbcl/bin/sbcl" --core "$HERE/ClotCAD.core" \
     --eval '(cl-occt-viewer:bootstrap)' \
     --eval '(sb-ext:quit)'
