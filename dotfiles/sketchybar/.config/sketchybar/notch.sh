#!/usr/bin/env bash

# Notch geometry, so no bar item ends up drawn behind the camera housing.
#
# Prints "<notch_width_pt>|<display ids without a notch>|<display ids with one>",
# e.g. "179|2|1". The ids are SketchyBar arrangement ids, comma separated, ready
# to hand to an item's display= property. A Mac with no notch prints "0|1|".
#
# NSScreen is the source of truth: auxiliaryTopLeftArea / auxiliaryTopRightArea
# are nil unless the screen has a notch, and the gap between the two *is* the
# notch. Nothing here is hardcoded per machine.

NOTCHED_SCREENS=$(swift -e '
import AppKit
for screen in NSScreen.screens {
    guard let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
          let left = screen.auxiliaryTopLeftArea,
          let right = screen.auxiliaryTopRightArea else { continue }
    print("\(number.intValue)|\(Int(screen.frame.width - left.width - right.width))")
}')

NOTCH_WIDTH=0
WITH_NOTCH=""
WITHOUT_NOTCH=""

while IFS='|' read -r DISPLAY_ID SCREEN_NUMBER; do
  [ -n "$DISPLAY_ID" ] || continue

  WIDTH=$(echo "$NOTCHED_SCREENS" | awk -F'|' -v screen="$SCREEN_NUMBER" '$1 == screen { print $2 }')

  if [ -n "$WIDTH" ]; then
    NOTCH_WIDTH=$WIDTH
    WITH_NOTCH="${WITH_NOTCH:+$WITH_NOTCH,}$DISPLAY_ID"
  else
    WITHOUT_NOTCH="${WITHOUT_NOTCH:+$WITHOUT_NOTCH,}$DISPLAY_ID"
  fi
done <<< "$(sketchybar --query displays | jq -r '.[] | "\(.["arrangement-id"])|\(.["DirectDisplayID"])"')"

echo "$NOTCH_WIDTH|$WITHOUT_NOTCH|$WITH_NOTCH"
