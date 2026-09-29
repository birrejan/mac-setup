#!/bin/bash

# A muted date and a brighter, tabular 24-hour clock.
sketchybar --set "$NAME" icon="$(date +'%a %d %b')" label="$(date +'%H:%M')"
