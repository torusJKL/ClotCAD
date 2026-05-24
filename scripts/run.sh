#!/bin/bash
HERE="$(dirname "$(readlink -f "$0")")"
export LD_LIBRARY_PATH="$HERE/lib/occt:$HERE/lib:$HERE/usr/lib"
export QT_PLUGIN_PATH="$HERE/lib/plugins"

usage() {
    cat <<EOF
Usage: $(basename "$0") [MODE] [OPTIONS]

Modes:
  --viewer              Start the 3D viewer (default)
  --slynk               Start headless Slynk server
  --alive               Start headless Alive LSP server

Options:
  -p, --port PORT       Set Slynk port (default: 4005)
  -a, --alive-port PORT Set Alive LSP port (default: 4006)

Examples:
  $0                    Start viewer with default ports
  $0 --slynk            Start headless Slynk on port 4005
  $0 --slynk -p 4007    Start headless Slynk on port 4007
  $0 --alive            Start headless Alive LSP on port 4006
  $0 --alive -a 4008    Start headless Alive LSP on port 4008
EOF
    exit 1
}

MODE=""
SLYNK_PORT=4005
ALIVE_PORT=4006

# Parse mode from first argument
case "${1:-}" in
    --viewer)    MODE="viewer"; shift ;;
    "")          MODE="viewer" ;;
    --slynk)     MODE="slynk"; shift ;;
    --alive)     MODE="alive"; shift ;;
    --help|-h)   usage ;;
    *)           echo "Unknown mode: $1"; usage ;;
esac

# Parse mode-specific flags
if [ "$MODE" = "viewer" ] || [ "$MODE" = "slynk" ] || [ "$MODE" = "alive" ]; then
    while [ $# -gt 0 ]; do
        case "$1" in
            -p|--port)
                if [ $# -lt 2 ]; then echo "error: --port requires an argument"; exit 2; fi
                SLYNK_PORT="$2"; shift 2 ;;
            -a|--alive-port)
                if [ $# -lt 2 ]; then echo "error: --alive-port requires an argument"; exit 2; fi
                ALIVE_PORT="$2"; shift 2 ;;
            *)
                echo "Unknown option: $1"; exit 2 ;;
        esac
    done
fi

case "$MODE" in
    viewer)
        export QT_QPA_PLATFORM=""
        exec "$HERE/sbcl/bin/sbcl" --core "$HERE/ClotCAD.core" \
            --eval "(clotcad:start-slynk :port $SLYNK_PORT)" \
            --eval "(clotcad:start-alive :port $ALIVE_PORT)" \
            --eval "(clotcad:start-viewer)" \
            --eval "(sb-ext:quit)"
        ;;
    slynk)
        export QT_QPA_PLATFORM=offscreen
        exec "$HERE/sbcl/bin/sbcl" --core "$HERE/ClotCAD.core" \
            --eval "(clotcad:start-slynk :port $SLYNK_PORT)" \
            --eval "(clotcad:wait-forever)" \
            --eval "(sb-ext:quit)"
        ;;
    alive)
        export QT_QPA_PLATFORM=offscreen
        exec "$HERE/sbcl/bin/sbcl" --core "$HERE/ClotCAD.core" \
            --eval "(clotcad:start-alive :port $ALIVE_PORT)" \
            --eval "(clotcad:wait-forever)" \
            --eval "(sb-ext:quit)"
        ;;
esac
