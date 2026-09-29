#!/bin/bash

sketchybar --add item media e \
           --set media label.color="$MUTED_COLOR" label.font="$TEXT_FONT:Regular:12.0" \
                       drawing=off \
                       label.max_chars=20 \
                       icon.padding_left=0 \
                       scroll_texts=off \
                       icon=􀑪             \
                       icon.color=$ACCENT_COLOR   \
                       script="$PLUGIN_DIR/media.sh" \
           --subscribe media media_change
