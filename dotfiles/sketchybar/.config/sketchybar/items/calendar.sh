#!/bin/bash

sketchybar --add item calendar right \
           --set calendar icon.font="$TEXT_FONT:Regular:12.0" \
                          icon.color="$MUTED_COLOR" icon.padding_right=10 \
                          label.font="$MONO_FONT:Medium:12.0" \
                          update_freq=30 \
                          script="$PLUGIN_DIR/calendar.sh"
