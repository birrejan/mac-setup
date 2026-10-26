#!/bin/bash

# Shared helpers for plugin scripts. Plugins get $CONFIG_DIR from sketchybar.
source "$CONFIG_DIR/colors.sh"

# threshold_color <value> <warn_at> <crit_at>
# Echoes the color a metric should be drawn in for the given value.
threshold_color() {
  local value=$1 warn=$2 crit=$3

  if [ "$value" -ge "$crit" ]; then
    echo "$CRIT_COLOR"
  elif [ "$value" -ge "$warn" ]; then
    echo "$WARN_COLOR"
  else
    echo "$WHITE"
  fi
}

# low_threshold_color <value> <warn_at> <crit_at>
# threshold_color for metrics where a *low* value is the problem, e.g. battery.
low_threshold_color() {
  local value=$1 warn=$2 crit=$3

  if [ "$value" -le "$crit" ]; then
    echo "$CRIT_COLOR"
  elif [ "$value" -le "$warn" ]; then
    echo "$WARN_COLOR"
  else
    echo "$WHITE"
  fi
}

