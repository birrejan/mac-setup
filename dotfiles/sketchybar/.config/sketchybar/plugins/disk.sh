#!/bin/bash

source "$CONFIG_DIR/helpers.sh"

# The Data volume is the one that actually fills up -- df on / only sees the
# read-only system snapshot and always reports a few used GB.
read -r AVAIL CAPACITY <<< "$(df -H /System/Volumes/Data | awk 'NR == 2 { print $4, $5 }')"
USED_PERCENT=${CAPACITY%\%}

# Like the CPU and memory cards, it only shows up once there is something to
# act on: the disk is 85% full, and red from 93%.
if [ -z "$USED_PERCENT" ] || [ "$USED_PERCENT" -lt 85 ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

COLOR=$(threshold_color "$USED_PERCENT" 85 93)

sketchybar --set "$NAME" drawing=on \
                        label="$AVAIL" \
                        label.color="$COLOR" \
                        icon.color="$COLOR"
