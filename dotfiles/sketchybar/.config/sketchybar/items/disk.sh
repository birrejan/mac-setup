#!/bin/bash

# Two copies of the card: the normal one in the right-hand cluster, and a twin
# anchored to the *left* of the camera notch. Only one is ever drawn on a given
# display -- plugins/notch_apply.sh picks, because the right-hand cluster does not
# fit in the ~635pt beside a notch, while the space left of it is empty.
# Hidden until the disk is nearly full; plugins/disk.sh decides.

for CARD in disk disk.notch; do
  POSITION=right
  [ "$CARD" = "disk.notch" ] && POSITION=q

  sketchybar --add item "$CARD" "$POSITION" \
             --set "$CARD" update_freq=60 \
                           drawing=off \
                           updates=on \
                           icon=􀧘 \
                           background.drawing=on \
                           script="$PLUGIN_DIR/disk.sh" \
                           click_script="open 'x-apple.systempreferences:com.apple.settings.Storage'"
done
