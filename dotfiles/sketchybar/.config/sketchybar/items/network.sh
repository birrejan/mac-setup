#!/bin/bash

# Two copies of the card: the normal one in the right-hand cluster, and a twin
# anchored to the *left* of the camera notch. Only one is ever drawn on a given
# display -- plugins/notch_apply.sh picks, because the right-hand cluster does not
# fit in the ~635pt beside a notch, while the space left of it is empty.
# Hidden while the Mac is online; plugins/network.sh decides.

for CARD in network network.notch; do
  POSITION=right
  [ "$CARD" = "network.notch" ] && POSITION=q

  sketchybar --add item "$CARD" "$POSITION" \
             --set "$CARD" update_freq=5 \
                           drawing=off \
                           updates=on \
                           icon=􀆪 \
                           background.drawing=on \
                           script="$PLUGIN_DIR/network.sh" \
                           click_script="open 'x-apple.systempreferences:com.apple.Network-Settings.extension'"
done
