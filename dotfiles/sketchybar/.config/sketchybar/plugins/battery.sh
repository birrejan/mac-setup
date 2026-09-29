#!/bin/bash

source "$CONFIG_DIR/helpers.sh"

BATT=$(pmset -g batt)
PERCENTAGE=$(echo "$BATT" | grep -Eo '[0-9]+%' | head -1 | cut -d% -f1)
CHARGING=$(echo "$BATT" | grep 'AC Power')

if [ -z "$PERCENTAGE" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

if [ -n "$CHARGING" ] && [ "$PERCENTAGE" -ge 20 ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

case ${PERCENTAGE} in
  9[0-9]|100) ICON="􀛨"
  ;;
  [6-8][0-9]) ICON="􀺸"
  ;;
  [3-5][0-9]) ICON="􀺶"
  ;;
  [1-2][0-9]) ICON="􀛩"
  ;;
  *) ICON="􀛪"
esac

if [ -n "$CHARGING" ]; then
  ICON="􀢋"
fi

if [ -z "$CHARGING" ]; then
  # On battery the useful second number is how long is left. pmset reports
  # 0:00 / (no estimate) for the first minutes after unplugging.
  REMAINING=$(echo "$BATT" | grep -Eo '[0-9]+:[0-9]{2}' | head -1)
  if [ -z "$REMAINING" ] || [ "$REMAINING" = "0:00" ]; then
    LABEL="${PERCENTAGE}%"
  else
    LABEL="${PERCENTAGE}% $REMAINING"
  fi
  COLOR=$(low_threshold_color "$PERCENTAGE" 20 10)
else
  # Plugged in, the useful second number is the charge rate in watts. Amperage
  # is a signed 64-bit value that ioreg prints unsigned, and it sits at 0 once
  # the battery is full -- in which case only the percentage is shown.
  WATTS=$(ioreg -rn AppleSmartBattery | awk '
    /^ +"InstantAmperage" = / { amperage = $3 }
    /^ +"Voltage" = /         { voltage = $3 }
    END {
      # A huge reading is ioreg printing a negative (discharging) amperage as
      # unsigned, which is not a charge rate -- so there is nothing to show.
      if (amperage <= 0 || amperage > 1000000000000000) { print 0; exit }
      printf "%.0f", (amperage * voltage) / 1000000
    }
  ')

  if [ -n "$WATTS" ] && [ "$WATTS" -gt 0 ]; then
    LABEL="${PERCENTAGE}% ${WATTS}W"
  else
    LABEL="${PERCENTAGE}%"
  fi
  COLOR=$WHITE
fi

sketchybar --set "$NAME" drawing=on icon="$ICON" \
                        icon.color="$COLOR" \
                        label="$LABEL" \
                        label.color="$COLOR"
