#!/bin/bash

sketchybar --add item battery right \
           --set battery update_freq=60 \
                         drawing=off \
                         updates=on \
                         script="$PLUGIN_DIR/battery.sh" \
                         click_script="open 'x-apple.systempreferences:com.apple.Battery-Settings.extension'" \
           --subscribe battery system_woke power_source_change
