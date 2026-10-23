#!/bin/bash

# Taskwarrior: the task you started, or what is due today. Hidden when neither;
# plugins/tasks.sh has what it shows and what a click does. The task_change
# event comes from the Taskwarrior hook ~/.config/task/hooks/on-exit.sketchybar,
# so a change shows at once; the timer catches tasks falling due.
sketchybar --add event task_change \
           --add item tasks right \
           --set tasks update_freq=60 \
                       drawing=off \
                       updates=on \
                       icon=TASK icon.font="$MONO_FONT:Medium:10.0" \
                       icon.color="$ACCENT_COLOR" \
                       script="$PLUGIN_DIR/tasks.sh" \
           --subscribe tasks task_change mouse.clicked system_woke
