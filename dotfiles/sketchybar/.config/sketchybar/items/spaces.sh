#!/bin/bash

# One updater owns all workspace pills and the focused-app label. Keep polling
# while hidden so window creation, empty workspaces and reconnects recover too.
sketchybar --add item system.aerospace.event left \
  --set system.aerospace.event drawing=off updates=on update_freq=5 \
      script="$CONFIG_DIR/plugins/aerospace.sh" \
  --subscribe system.aerospace.event aerospace_workspace_change \
      space_change space_windows_change display_change front_app_switched system_woke

sketchybar --add item front_app left \
  --set front_app drawing=off background.drawing=off \
      icon="·" icon.color="$DIM_COLOR" icon.padding_left=12 icon.padding_right=10 \
      label.max_chars=24 label.font="$TEXT_FONT:Medium:12.0" label.color="$MUTED_COLOR"
