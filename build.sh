#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/dist/NoomiMod.app"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "NoomiMod must be built on macOS. This script uses Apple's Swift compiler and AppKit." >&2
  exit 1
fi
if ! command -v swiftc >/dev/null 2>&1; then
  echo "Swift compiler not found. Install Apple's standalone Command Line Tools (not the full Xcode app), then run this script again." >&2
  exit 1
fi

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$ROOT/Info.plist" "$APP/Contents/Info.plist"
swiftc -O -target "$(uname -m)-apple-macosx12.0" -framework Cocoa -framework UniformTypeIdentifiers \
  "$ROOT/NoomiMod.swift" -o "$APP/Contents/MacOS/NoomiMod"

if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP"
fi

echo "Built: $APP"
