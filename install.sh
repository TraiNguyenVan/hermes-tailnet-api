#!/bin/sh
# hermes-tailnet-api — one-shot installer.
#
# (jsDelivr, not raw.githubusercontent — raw serves stale bytes for minutes)
#   curl -fsSL https://cdn.jsdelivr.net/gh/TraiNguyenVan/hermes-tailnet-api@main/install.sh | sh
#   ./install.sh                      (from a clone or unpacked copy)
#
# Env: HERMES_API_BASE, HERMES_API_KEY (both else prompted),
#      HERMES_SKILL_DIR, HERMES_PKG_URL, HERMES_BIN_DIR
set -eu

NAME=hermes-tailnet-api
DEST="${HERMES_SKILL_DIR:-$HOME/.agents/skills/$NAME}"
PKG_URL="${HERMES_PKG_URL:-https://cdn.jsdelivr.net/gh/TraiNguyenVan/hermes-tailnet-api@main}"

FILE_DIR=""
for cand in "$(dirname "$0")" "."; do
  if [ -f "$cand/SKILL.md" ] && [ -f "$cand/scripts/hermes-api" ]; then
    FILE_DIR=$(cd "$cand" && pwd); break
  fi
done

mkdir -p "$DEST/scripts" "$DEST/references"

fetch() {  # fetch <relative path> <destination>
  if [ -n "$FILE_DIR" ] && [ -f "$FILE_DIR/$1" ]; then
    cp "$FILE_DIR/$1" "$2"
  else
    curl -fsSL "$PKG_URL/$1" -o "$2" || { echo "failed to fetch $1 from $PKG_URL" >&2; exit 1; }
  fi
}

fetch SKILL.md "$DEST/SKILL.md"
fetch references/api.md "$DEST/references/api.md"
fetch scripts/hermes-api "$DEST/scripts/hermes-api"
fetch scripts/setup.sh "$DEST/scripts/setup.sh"
chmod +x "$DEST/scripts/hermes-api" "$DEST/scripts/setup.sh"
echo "installed skill -> $DEST"

"$DEST/scripts/setup.sh"
echo
echo "done. Restart your agent so it picks up ~/.agents/skills/$NAME."
echo "upgrade later:  npx skills update -g -y   (or re-run this installer)"
