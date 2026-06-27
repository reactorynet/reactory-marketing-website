#!/usr/bin/env bash
# serve.sh — Development HTTP server for the what-is-reactory one-pager
# Usage: ./serve.sh [OPTIONS]
#
# Options:
#   -p, --port  PORT    Port to listen on (default: 8000)
#   -d, --dir   DIR     Root directory to serve (default: parent of this script)
#   -o, --open          Open the page in the default browser after starting
#   -h, --help          Show this help text

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_ROOT="$(dirname "$SCRIPT_DIR")"

PORT=8000
ROOT_DIR="$DEFAULT_ROOT"
OPEN_BROWSER=false

# ── Argument parsing ─────────────────────────────────────────────────────────
usage() {
  grep '^#' "$0" | sed 's/^# \{0,1\}//'
  exit 0
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--port)
      PORT="${2:?'--port requires a value'}"
      shift 2
      ;;
    -d|--dir)
      ROOT_DIR="${2:?'--dir requires a value'}"
      shift 2
      ;;
    -o|--open)
      OPEN_BROWSER=true
      shift
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Unknown option: $1" >&2
      echo "Run with --help for usage." >&2
      exit 1
      ;;
  esac
done

# ── Validation ───────────────────────────────────────────────────────────────
if ! command -v node &>/dev/null; then
  echo "Error: node is not installed or not on PATH." >&2
  exit 1
fi

if [[ ! -f "$SCRIPT_DIR/serve.js" ]]; then
  echo "Error: serve.js not found in $SCRIPT_DIR" >&2
  exit 1
fi

if [[ ! -d "$ROOT_DIR" ]]; then
  echo "Error: root directory does not exist: $ROOT_DIR" >&2
  exit 1
fi

# ── Port availability check ──────────────────────────────────────────────────
if lsof -iTCP:"$PORT" -sTCP:LISTEN -t &>/dev/null; then
  echo "Warning: port $PORT is already in use. Trying $((PORT + 1))..." >&2
  PORT=$((PORT + 1))
fi

# ── Launch ───────────────────────────────────────────────────────────────────
URL="http://localhost:${PORT}"

echo "Starting server..."
echo "  Root : $ROOT_DIR"
echo "  URL  : $URL"
echo ""

if [[ "$OPEN_BROWSER" == true ]]; then
  # Brief delay to let the server bind before opening the browser
  (sleep 0.8 && open "$URL" 2>/dev/null || xdg-open "$URL" 2>/dev/null || true) &
fi

export HTTP_SERVER_PORT="$PORT"
export ROOT_DIR="$ROOT_DIR"

exec node "$SCRIPT_DIR/serve.js"
