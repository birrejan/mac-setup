#!/bin/bash

source "$CONFIG_DIR/helpers.sh"

# Only shows up when the Mac is offline, i.e. there is no default route. Wi-Fi
# that is joined but has no internet still counts as online.
if route -n get default >/dev/null 2>&1; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

sketchybar --set "$NAME" drawing=on \
                        label="offline" \
                        label.color="$WARN_COLOR" \
                        icon.color="$WARN_COLOR"
