#!/bin/sh
# Cut a release: bump the version everywhere, commit, tag, push.
#   scripts/release.sh 1.1.0
# Consumers then run:  npx skills update hermes-tailnet-api -g -y
set -eu

[ $# -eq 1 ] || { echo "usage: $0 <version>   (e.g. 1.1.0)" >&2; exit 2; }
V=$1
case "$V" in *[!0-9.]*) echo "version must be numeric like 1.2.3" >&2; exit 2 ;; esac

DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$DIR"

# one version, three files
sed -i.bak "s/^version: .*/version: $V/" SKILL.md && rm -f SKILL.md.bak
sed -i.bak "s/^__version__ = .*/__version__ = \"$V\"/" scripts/hermes-api && rm -f scripts/hermes-api.bak
sed -i.bak "s/^VERSION=.*/VERSION=\"$V\"/" install.sh && rm -f install.sh.bak

git add -A
git commit -qm "release: v$V"
git tag -a "v$V" -m "v$V"
git push -q origin main --follow-tags
echo "released v$V — $(git rev-parse --short HEAD)"
echo "consumers upgrade with: npx skills update hermes-tailnet-api -g -y"
