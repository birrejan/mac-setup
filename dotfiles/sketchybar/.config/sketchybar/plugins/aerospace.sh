#!/usr/bin/env bash

if [ "$SENDER" = "aerospace_workspace_change" ]; then
  if [ "$1" = "$FOCUSED_WORKSPACE" ]; then
    sketchybar --set "$NAME" background.drawing=on
  else
    sketchybar --set "$NAME" background.drawing=off
  fi
fi

# Redraw workspaces and apps on changes to the right display
if [ "$SENDER" = "space_windows_change" ] || [ "$SENDER" = "front_app_switched" ] || [ "$SENDER" = "display_change" ]; then
  ITEMS_LIST="$(sketchybar --query bar | jq -r '.items[]')"
  item_exists() {
    echo "$ITEMS_LIST" | grep -q "^$1$"
  }

  # Assign correct Aerospace workspaces
  while IFS='|' read -r DISPLAY_ID NSSCREEN_ID AERO_ID AERO_NAME; do

    for sid in $(aerospace list-workspaces --monitor "$AERO_ID" </dev/null); do
      sketchybar --set "space.$sid" \
        display="$DISPLAY_ID" \
        label="$sid"  # Displays the workspace number as the label

      APPS="$(aerospace list-windows --workspace "$sid" --json </dev/null | jq -r 'map(."app-name") | join(", ")')"

      # Combine the workspace number and app names
      WORKSPACE_LABEL="$sid: $APPS"

      # Check if the current workspace is the focused/active workspace
      if [ "$sid" = "$FOCUSED_WORKSPACE" ]; then
        # Active workspace, apply a different color (e.g., red)
        sketchybar --set "space.$sid" label="$WORKSPACE_LABEL" label.color=0xff00ff
      else
        # Not the active workspace, apply default color (e.g., white)
        sketchybar --set "space.$sid" label="$WORKSPACE_LABEL" label.color=0xffffffff
      fi

      # Only create the item if there are actual applications and it does not exist yet
      if [ -n "$APPS" ]; then
        if ! item_exists "space.$sid.apps"; then
          sketchybar --add space "space.$sid.apps" left
        fi
        sketchybar --set "space.$sid.apps" \
          display="$DISPLAY_ID" \
          label="$WORKSPACE_LABEL"  # Shows both workspace number and apps
      else
        # Only remove the item if it exists
        if item_exists "space.$sid.apps"; then
          sketchybar --remove "space.$sid.apps"
        fi
      fi
    done
  done < <("$CONFIG_DIR/match_displays.sh")
fi
