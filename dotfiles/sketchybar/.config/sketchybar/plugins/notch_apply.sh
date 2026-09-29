#!/usr/bin/env bash

# Keeps items out from behind the camera housing. Runs at startup and again on
# display_change, because plugging a monitor in renumbers the displays.
#
# Two separate things are needed:
#
#   notch_width  tells the bar where the notch is. This is what makes `e` items
#                (the media card) start to the right of it instead of underneath.
#
#   display=     is for the right-hand cards, which the bar does *not* keep clear
#                of the notch -- they stack leftwards from the right edge and slide
#                under it. Leave room for the battery and CPU to appear together
#                by keeping RAM and capture status on the other side of the notch.
#                Each has a `.notch` twin at position q
#                (see items/memory.sh); this decides which copy a display draws.
#
# Only display= is touched here, never drawing= -- the capture card owns its own
# drawing flag. display=0 matches no display, which is how a copy is parked.

CARDS_THAT_DO_NOT_FIT=(memory capture)

IFS='|' read -r NOTCH_WIDTH DISPLAYS_WITHOUT_NOTCH DISPLAYS_WITH_NOTCH <<< "$("$CONFIG_DIR/notch.sh")"

sketchybar --bar notch_width="$NOTCH_WIDTH"

# Keep long titles compact when the main display has a camera notch.
case ",$DISPLAYS_WITH_NOTCH," in
  *,1,*) sketchybar --set front_app label.max_chars=14 --set media label.max_chars=12 ;;
  *) sketchybar --set front_app label.max_chars=24 --set media label.max_chars=20 ;;
esac

for CARD in "${CARDS_THAT_DO_NOT_FIT[@]}"; do
  # The right-hand copy goes on every display with room for it, which is every
  # display at all on a Mac without a notch.
  sketchybar --set "$CARD" display="${DISPLAYS_WITHOUT_NOTCH:-0}"

  # The left-of-notch twin goes only on displays that actually have a notch.
  sketchybar --set "$CARD.notch" display="${DISPLAYS_WITH_NOTCH:-0}"
done
