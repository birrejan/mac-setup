#!/bin/bash

# Lights up only while the mic or camera is actually live -- hidden otherwise.
# Two copies, like the other cards that cannot share the right-hand cluster with a
# notch: this one would land on top of the media card in its widest state, so on a
# notched display the twin at position q is used instead. Each copy runs the plugin
# for itself, which is what turns it on and off; notch_apply.sh only decides which
# display each copy belongs to.
for CARD in capture capture.notch; do
  POSITION=right
  [ "$CARD" = "capture.notch" ] && POSITION=q

  sketchybar --add item "$CARD" "$POSITION" \
             --set "$CARD" update_freq=2 \
                           drawing=off \
                           background.drawing=on \
                           label.padding_left=0 \
                           script="$PLUGIN_DIR/capture.sh"
done
