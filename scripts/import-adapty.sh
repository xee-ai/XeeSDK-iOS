#!/usr/bin/env bash
# Fetches Adapty iOS SDK 3.17.3 (MIT) into this package. Run once, from anywhere.
set -euo pipefail

TAG=3.17.3
ROOT=$(cd "$(dirname "$0")/.." && pwd)

for dir in Sources Sources.Logger Tests; do
  if [ -e "$ROOT/$dir" ]; then
    echo "$dir already exists: the import was already done" >&2
    exit 1
  fi
done

TMP=$(mktemp -d)
git clone --quiet --depth 1 --branch "$TAG" https://github.com/adaptyteam/AdaptySDK-iOS.git "$TMP/src"
cp -R "$TMP/src/Sources" "$TMP/src/Sources.Logger" "$TMP/src/Tests" "$ROOT/"
cp "$TMP/src/LICENSE" "$ROOT/LICENSE"
# Agent instruction files from Adapty's repo are not ours.
rm -f "$ROOT/Tests/AGENTS.md" "$ROOT/Tests/CLAUDE.md"
echo "imported Adapty iOS SDK $TAG into $ROOT"
