#!/bin/bash
set -euo pipefail

REPO="ttmeticks-source/Test1"
BRANCH="main"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/noomimod.XXXXXX")"
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "NoomiMod's .app installer runs on macOS only." >&2
  exit 1
fi

ARCHIVE_URL="https://github.com/${REPO}/archive/refs/heads/${BRANCH}.tar.gz"
echo "Downloading NoomiMod source from GitHub…"
curl --fail --location --silent --show-error --retry 3 "$ARCHIVE_URL" -o "$TMP_DIR/noomimod.tar.gz"
tar -xzf "$TMP_DIR/noomimod.tar.gz" -C "$TMP_DIR"
PROJECT_DIR="$TMP_DIR/Test1-${BRANCH}"

"$PROJECT_DIR/build.sh"
APP_SOURCE="$PROJECT_DIR/dist/NoomiMod.app"

if [[ -w "/Applications" ]]; then
  DEST_DIR="/Applications"
else
  DEST_DIR="$HOME/Applications"
  mkdir -p "$DEST_DIR"
fi

rm -rf "$DEST_DIR/NoomiMod.app"
cp -R "$APP_SOURCE" "$DEST_DIR/NoomiMod.app"
echo "Installed: $DEST_DIR/NoomiMod.app"
open "$DEST_DIR/NoomiMod.app"
