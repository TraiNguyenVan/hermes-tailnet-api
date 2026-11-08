#!/bin/sh
# hermes-tailnet-api — one-shot installer.
#
#   curl -fsSL https://raw.githubusercontent.com/TraiNguyenVan/hermes-tailnet-api/v1.0.6/install.sh | sh
#   ./install.sh                      (from a clone or unpacked copy)
#
# Env: HERMES_API_BASE, HERMES_API_KEY (both else prompted),
#      HERMES_SKILL_DIR, HERMES_PKG_URL, HERMES_BIN_DIR
set -eu

NAME=hermes-tailnet-api
DEST="${HERMES_SKILL_DIR:-$HOME/.agents/skills/$NAME}"
VERSION="1.3.0"
# Payload comes from the immutable tag matching THIS installer, from two CDNs.
# Never fall back to a branch ref: @main serves stale, per-file, mixed versions
# for minutes to hours, which silently installs a mismatched skill.
PKG_URL="${HERMES_PKG_URL:-https://raw.githubusercontent.com/TraiNguyenVan/hermes-tailnet-api/v$VERSION}"
FALLBACK_URL="https://cdn.jsdelivr.net/gh/TraiNguyenVan/hermes-tailnet-api@v$VERSION"

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
    curl -fsSL "$PKG_URL/$1" -o "$2" \
      || curl -fsSL "$FALLBACK_URL/$1" -o "$2" \
      || { echo "failed to fetch $1 from $PKG_URL" >&2; exit 1; }
  fi
}

fetch SKILL.md "$DEST/SKILL.md"
fetch references/api.md "$DEST/references/api.md"
fetch scripts/hermes-api "$DEST/scripts/hermes-api"
fetch scripts/setup.sh "$DEST/scripts/setup.sh"
chmod +x "$DEST/scripts/hermes-api" "$DEST/scripts/setup.sh"

# Self-check: never finish on a mixed-version install.
if ! grep -q "^version: $VERSION" "$DEST/SKILL.md" \
   || ! grep -q "__version__ = \"$VERSION\"" "$DEST/scripts/hermes-api"; then
  echo "ERROR: installed files are not version $VERSION" >&2
  echo "  SKILL.md says: $(grep -m1 '^version:' "$DEST/SKILL.md" || echo '?')" >&2
  exit 1
fi
echo "installed skill v$VERSION -> $DEST"

"$DEST/scripts/setup.sh"
echo
echo "done. Restart your agent so it picks up ~/.agents/skills/$NAME."
echo "upgrade later:  npx skills update $NAME -g -y   (or re-run this installer)"
