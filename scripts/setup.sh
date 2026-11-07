#!/bin/sh
# hermes-api setup: link the CLI onto PATH, store server URL + API key, verify.
set -eu

SKILL_DIR=$(cd "$(dirname "$0")/.." && pwd)
BIN_DIR="${HERMES_BIN_DIR:-$HOME/.local/bin}"
CONF_DIR="$HOME/.config/hermes"
CONF="$CONF_DIR/api.env"

mkdir -p "$BIN_DIR" "$CONF_DIR"

chmod +x "$SKILL_DIR/scripts/hermes-api"
ln -sf "$SKILL_DIR/scripts/hermes-api" "$BIN_DIR/hermes-api"
echo "linked $BIN_DIR/hermes-api -> $SKILL_DIR/scripts/hermes-api"

BASE="${HERMES_API_BASE:-}"
if [ -z "$BASE" ]; then
  printf 'Hermes API base URL (e.g. http://100.x.y.z:8642/v1): '
  read -r BASE
fi
case "$BASE" in
  http://*|https://*) ;;
  *) echo "base URL must start with http:// or https://" >&2; exit 1 ;;
esac
BASE=${BASE%/}
case "$BASE" in
  */v1) ;;
  *) echo "note: base usually ends in /v1 — using as given: $BASE" ;;
esac

KEY="${HERMES_API_KEY:-${1:-}}"
if [ -z "$KEY" ]; then
  printf 'Hermes API key (API_SERVER_KEY): '
  stty -echo 2>/dev/null || true   # keep it out of scrollback
  read -r KEY
  stty echo 2>/dev/null || true
  printf '\n'
fi
[ -n "$KEY" ] || { echo "no key given — aborting" >&2; exit 1; }

umask 077
{
  printf 'HERMES_API_KEY=%s\n' "$KEY"
  printf 'HERMES_API_BASE=%s\n' "$BASE"
} > "$CONF"
chmod 600 "$CONF"
echo "wrote $CONF (600)"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "note: $BIN_DIR is not on PATH; add: export PATH=\"$BIN_DIR:\$PATH\"" ;;
esac

echo "checking connectivity..."
"$BIN_DIR/hermes-api" models
