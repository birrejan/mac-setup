#!/bin/bash

source "$CONFIG_DIR/helpers.sh"

# Memory usage, approximating Activity Monitor's "Memory Used":
# active + wired + compressed pages, as a share of physical memory.
MEM_STATS=$(vm_stat)
PAGE_SIZE=$(echo "$MEM_STATS" | head -1 | grep -Eo '[0-9]+')
MEM_TOTAL=$(sysctl -n hw.memsize)

MEM_PERCENT=$(echo "$MEM_STATS" | awk -v page_size="$PAGE_SIZE" -v total="$MEM_TOTAL" '
  /Pages active/                    { active = $3 }
  /Pages wired down/                { wired = $4 }
  /Pages occupied by compressor/    { compressed = $5 }
  END { printf "%.0f", ((active + wired + compressed) * page_size / total) * 100 }
')

if [ "$MEM_PERCENT" -le 70 ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

# macOS runs a high used-% by design, so the color is driven mainly by the
# kernel's own memory pressure level (1 = normal, 2 = warning, 4 = critical) --
# that is what actually predicts swapping and the machine feeling slow.
PRESSURE=$(sysctl -n kern.memorystatus_vm_pressure_level 2>/dev/null || echo 1)
COLOR=$WHITE

if [ "$PRESSURE" -ge 4 ]; then
  COLOR=$CRIT_COLOR
elif [ "$PRESSURE" -ge 2 ]; then
  COLOR=$WARN_COLOR
fi

sketchybar --set "$NAME" drawing=on label="$MEM_PERCENT%" \
                        label.color="$COLOR" \
                        icon.color="$COLOR"
