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
  -i, --init FILE       Load FILE as init script instead of ~/.config/clotcad/init.lisp
  --no-init             Do not load any init script

Examples:
  $0                    Start viewer with default ports
  $0 --slynk            Start headless Slynk on port 4005
  $0 --slynk -p 4007    Start headless Slynk on port 4007
  $0 --alive            Start headless Alive LSP on port 4006
  $0 --alive -a 4008    Start headless Alive LSP on port 4008
  $0 --init ~/my-setup.lisp  Start viewer with custom init script
  $0 --no-init          Start viewer without loading any init script
EOF
    exit 1
}

MODE=""
SLYNK_PORT=4005
ALIVE_PORT=4006
INIT_FILE=""
NO_INIT=""

# Parse mode from first argument
case "${1:-}" in
    --viewer)    MODE="viewer"; shift ;;
    "")          MODE="viewer" ;;
    --slynk)     MODE="slynk"; shift ;;
    --alive)     MODE="alive"; shift ;;
    --help|-h)   usage ;;
    *)           MODE="viewer" ;;
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
            -i|--init)
                if [ $# -lt 2 ]; then echo "error: --init requires an argument"; exit 2; fi
                INIT_FILE="$2"; shift 2 ;;
            --no-init)
                NO_INIT="1"; shift ;;
            --help|-h)
                usage ;;
            *)
                echo "Unknown option: $1"; exit 2 ;;
        esac
    done
fi

# Set init file via environment variable to avoid shell quoting issues
if [ -n "$NO_INIT" ]; then
    CLOTCAD_NO_INIT=1
elif [ -n "$INIT_FILE" ]; then
    export CLOTCAD_INIT_FILE="$INIT_FILE"
fi

case "$MODE" in
    viewer)
        export QT_QPA_PLATFORM=""
        sbcl_args=(--core "$HERE/ClotCAD.core")
        if [ "${CLOTCAD_NO_INIT:-}" = "1" ]; then
            sbcl_args+=(--eval "(setf clotcad::*no-init* t)")
        elif [ -n "${CLOTCAD_INIT_FILE:-}" ]; then
            sbcl_args+=(--eval "(setf clotcad::*init-file-path* \"$CLOTCAD_INIT_FILE\")")
        fi
        sbcl_args+=(--eval "(clotcad:start-slynk :port $SLYNK_PORT)")
        sbcl_args+=(--eval "(clotcad:start-alive :port $ALIVE_PORT)")
        sbcl_args+=(--eval "(clotcad:start-viewer)")
        sbcl_args+=(--eval "(sb-ext:quit)")
        exec "$HERE/sbcl/bin/sbcl" "${sbcl_args[@]}"
        ;;
    slynk)
        export QT_QPA_PLATFORM=offscreen
        sbcl_args=(--core "$HERE/ClotCAD.core")
        if [ "${CLOTCAD_NO_INIT:-}" = "1" ]; then
            sbcl_args+=(--eval "(setf clotcad::*no-init* t)")
        elif [ -n "${CLOTCAD_INIT_FILE:-}" ]; then
            sbcl_args+=(--eval "(setf clotcad::*init-file-path* \"$CLOTCAD_INIT_FILE\")")
        fi
        sbcl_args+=(--eval "(clotcad::load-init-file-headless)")
        sbcl_args+=(--eval "(clotcad:start-slynk :port $SLYNK_PORT)")
        sbcl_args+=(--eval "(clotcad:wait-forever)")
        sbcl_args+=(--eval "(sb-ext:quit)")
        exec "$HERE/sbcl/bin/sbcl" "${sbcl_args[@]}"
        ;;
    alive)
        export QT_QPA_PLATFORM=offscreen
        sbcl_args=(--core "$HERE/ClotCAD.core")
        if [ "${CLOTCAD_NO_INIT:-}" = "1" ]; then
            sbcl_args+=(--eval "(setf clotcad::*no-init* t)")
        elif [ -n "${CLOTCAD_INIT_FILE:-}" ]; then
            sbcl_args+=(--eval "(setf clotcad::*init-file-path* \"$CLOTCAD_INIT_FILE\")")
        fi
        sbcl_args+=(--eval "(clotcad::load-init-file-headless)")
        sbcl_args+=(--eval "(clotcad:start-alive :port $ALIVE_PORT)")
        sbcl_args+=(--eval "(clotcad:wait-forever)")
        sbcl_args+=(--eval "(sb-ext:quit)")
        exec "$HERE/sbcl/bin/sbcl" "${sbcl_args[@]}"
        ;;
esac
