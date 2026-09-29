#!/bin/bash

source "$CONFIG_DIR/helpers.sh"

HELPER="$CONFIG_DIR/bin/capture_state"
HELPER_SOURCE="$HELPER.swift"

# Built on first run and after any edit, so the repo carries source, not a binary.
if [ ! -x "$HELPER" ] || [ "$HELPER_SOURCE" -nt "$HELPER" ]; then
  if ! swiftc -O -o "$HELPER" "$HELPER_SOURCE" 2>/dev/null; then
    sketchybar --set "$NAME" drawing=off
    exit 0
  fi
fi

MIC_ICON="􀊱"
CAMERA_ICON="􀍊"

case "$("$HELPER" 2>/dev/null)" in
  "mic camera")
    ICON=$CAMERA_ICON; LABEL=$MIC_ICON; COLOR=$CRIT_COLOR; LABEL_DRAWING=on
    ;;
  "mic")
    ICON=$MIC_ICON; LABEL=""; COLOR=$WARN_COLOR; LABEL_DRAWING=off
    ;;
  "camera")
    ICON=$CAMERA_ICON; LABEL=""; COLOR=$CRIT_COLOR; LABEL_DRAWING=off
    ;;
  *)
    # Nothing is capturing, so the item stays out of the way entirely.
    sketchybar --set "$NAME" drawing=off
    exit 0
    ;;
esac

sketchybar --set "$NAME" drawing=on \
                        icon="$ICON" \
                        icon.color="$COLOR" \
                        label="$LABEL" \
                        label.color="$COLOR" \
                        label.drawing="$LABEL_DRAWING"
