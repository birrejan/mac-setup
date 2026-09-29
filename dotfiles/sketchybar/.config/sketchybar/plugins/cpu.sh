#!/bin/bash

source "$CONFIG_DIR/helpers.sh"

CORE_COUNT=$(sysctl -n machdep.cpu.thread_count)
CPU_PERCENT=$(ps -A -o %cpu= | awk -v cores="$CORE_COUNT" '{sum += $1} END {printf "%.0f", sum / cores}')

if [ "$CPU_PERCENT" -le 70 ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi
COLOR=$(threshold_color "$CPU_PERCENT" 70 90)

sketchybar --set "$NAME" drawing=on label="$CPU_PERCENT%" \
                      label.color="$COLOR" \
                      icon.color="$COLOR"
