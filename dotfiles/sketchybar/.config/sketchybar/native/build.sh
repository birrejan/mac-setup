#!/bin/bash
set -euo pipefail
SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
APP="$HOME/Library/Application Support/AeroToolbar/ToolbarBridge.app"
BIN="$APP/Contents/MacOS/ToolbarBridge"
mkdir -p "$APP/Contents/MacOS"
if [ ! -x "$BIN" ] || [ "$SOURCE_DIR/ToolbarBridge.swift" -nt "$BIN" ] || [ "$SOURCE_DIR/Info.plist" -nt "$BIN" ]; then
  /usr/bin/swiftc -O "$SOURCE_DIR/ToolbarBridge.swift" -o "$BIN.next"
  cp "$SOURCE_DIR/Info.plist" "$APP/Contents/Info.plist"
  mv "$BIN.next" "$BIN"
  /usr/bin/codesign --force --sign - "$APP"
fi
