#!/bin/bash

sketchybar --add item cpu right \
           --set cpu  update_freq=2 \
                      drawing=off \
                      updates=on \
                      icon=CPU icon.font="$MONO_FONT:Medium:10.0" \
                      background.drawing=on \
                      script="$PLUGIN_DIR/cpu.sh" \
                      click_script="$PLUGIN_DIR/open_btop.sh"
