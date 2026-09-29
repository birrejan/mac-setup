#!/bin/bash

# Mouse controls use AeroSpace; macOS volume events refresh the indicator.
# SketchyBar reports effective volume as zero while the output is muted.
case "$SENDER" in
  mouse.clicked)
    if [ "${BUTTON:-left}" = right ]; then
      exec "$CONFIG_DIR/plugins/toolbar.sh" audio
    fi
    [ "${BUTTON:-left}" = left ] || exit 0
    aerospace volume mute-toggle --no-gui
    exit $?
    ;;
  mouse.scrolled)
    [[ "${SCROLL_DELTA:-}" =~ ^-?[0-9]+$ ]] || exit 0
    if [ "$SCROLL_DELTA" -gt 0 ]; then
      aerospace volume up --no-gui
    elif [ "$SCROLL_DELTA" -lt 0 ]; then
      aerospace volume down --no-gui
    fi
    exit $?
    ;;
  volume_change)
    [[ "${INFO:-}" =~ ^[0-9]+([.][0-9]+)?$ ]] || exit 0
    VOLUME=$(awk -v volume="$INFO" 'BEGIN {
      if (volume < 0) volume = 0;
      if (volume > 100) volume = 100;
      printf "%.0f", volume
    }')
    ;;
  *) exit 0 ;;
esac

case $VOLUME in
  [6-9][0-9]|100) ICON="􀊩" ;;
  [3-5][0-9]) ICON="􀊥" ;;
  [1-9]|[1-2][0-9]) ICON="􀊡" ;;
  *) ICON="􀊣" ;;
esac

sketchybar --set "$NAME" icon="$ICON" label="$VOLUME%"
