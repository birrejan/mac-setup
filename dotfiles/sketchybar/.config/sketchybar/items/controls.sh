#!/bin/bash

# One menu for occasional controls; ongoing timers and meetings get small pills.
sketchybar --add item controls right \
  --set controls icon="⚙" label.drawing=off updates=on update_freq=5 \
    script="'$PLUGIN_DIR/toolbar.sh' event" \
  --subscribe controls mouse.clicked mouse.exited.global display_change system_woke

for ITEM in presentation awake focus granola meeting; do
  sketchybar --add item "$ITEM" right \
    --set "$ITEM" drawing=off background.drawing=off \
      icon.font="$MONO_FONT:Medium:10.0" icon.color="$ACCENT_COLOR"
done
sketchybar --set presentation icon="PRESENT" label.drawing=off \
    click_script="'$PLUGIN_DIR/toolbar.sh' presentation" \
  --set awake icon="AWAKE" click_script="'$PLUGIN_DIR/toolbar.sh' menu" \
  --set focus icon="FOCUS" click_script="'$PLUGIN_DIR/toolbar.sh' timer-click" \
  --set granola icon="􀊱" icon.font="$TEXT_FONT:Regular:14.0" label.drawing=off \
    click_script="'$PLUGIN_DIR/toolbar.sh' granola-record" \
  --set meeting icon="MTG" label.max_chars=32 \
    script="'$PLUGIN_DIR/meeting.sh'" \
  --subscribe meeting mouse.clicked

for ITEM in controls volume meeting; do
  sketchybar --set "$ITEM" popup.align=right popup.height=29 popup.y_offset=5 \
    popup.background.color="$BAR_COLOR" popup.background.border_color="$BORDER_COLOR" \
    popup.background.border_width=1 popup.background.corner_radius=7
done

"$CONFIG_DIR/native/build.sh" &&
  /usr/bin/open -gj "$HOME/Library/Application Support/AeroToolbar/ToolbarBridge.app" --args watch
