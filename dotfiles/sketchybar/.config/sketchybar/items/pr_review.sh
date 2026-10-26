#!/bin/bash

# Claude's PR reviews, started from gh-dash with I (`pr-review ai`). Hidden until
# one starts; plugins/pr_review.sh has what it shows and what a click does.
sketchybar --add item pr_review right \
           --set pr_review update_freq=2 \
                           drawing=off \
                           updates=on \
                           background.drawing=off \
                           icon=REVIEW icon.font="$MONO_FONT:Medium:10.0" \
                           icon.color="$ACCENT_COLOR" \
                           script="$PLUGIN_DIR/pr_review.sh" \
           --subscribe pr_review mouse.clicked
