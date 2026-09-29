#!/bin/bash

# Invisible item that exists only to re-run the notch layout when a display is
# plugged in or unplugged. Also runs once via the --update at the end of the rc.
sketchybar --add item notch.watcher left \
           --set notch.watcher drawing=off \
                               script="$PLUGIN_DIR/notch_apply.sh" \
           --subscribe notch.watcher display_change
