#!/bin/bash

# Two copies of the card: the normal one in the right-hand cluster, and a twin
# anchored to the *left* of the camera notch. Only one is ever drawn on a given
# display -- plugins/notch_apply.sh picks, because the right-hand cluster does not
# fit in the ~635pt beside a notch, while the space left of it is empty.

for CARD in memory memory.notch; do
  POSITION=right
  [ "$CARD" = "memory.notch" ] && POSITION=q

  sketchybar --add item "$CARD" "$POSITION" \
             --set "$CARD" update_freq=5 \
                           drawing=off \
                           updates=on \
                           icon=RAM icon.font="$MONO_FONT:Medium:10.0" \
                           background.drawing=on \
                           script="$PLUGIN_DIR/memory.sh" \
                           click_script="$PLUGIN_DIR/open_btop.sh"
done
