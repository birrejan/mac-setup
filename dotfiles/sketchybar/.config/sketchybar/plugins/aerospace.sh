#!/bin/bash

source "$CONFIG_DIR/colors.sh"
STATE_DIR="$HOME/Library/Application Support/AeroToolbar"
COMPACT=false
[ ! -f "$STATE_DIR/compact" ] || COMPACT=true

# Coalesce overlapping focus/window events. shlock also recovers a lock left by
# a terminated process; the routine update catches any event coalesced here.
LOCK="${TMPDIR:-/tmp}/sketchybar-aerospace-${UID}.lock"
/usr/bin/shlock -p $$ -f "$LOCK" || exit 0
trap 'rm -f "$LOCK"' EXIT
trap 'exit 0' INT TERM

MONITORS=$(aerospace list-monitors --json) || exit 0
WORKSPACES=$(aerospace list-workspaces --all --format '%{workspace} %{monitor-id}' --json) || exit 0
VISIBLE=$(aerospace list-workspaces --monitor all --visible --json) || exit 0
WINDOWS=$(aerospace list-windows --all --format '%{workspace}' --json) || exit 0
FOCUSED_WORKSPACE=$(aerospace list-workspaces --focused) || exit 0
FOCUSED_APP=$(aerospace list-windows --focused --format '%{app-name}' 2>/dev/null)
ITEMS=$(sketchybar --query bar | jq -r '.items[]') || exit 0

# Each monitor has a compact heading, followed by its numbered workspaces.
# Fixed Chat/Calendar/Email workspaces and active workspaces stay visible even
# when empty. Plain items avoid macOS Mission Control associations.
ROWS=$(jq -nr --argjson monitors "$MONITORS" --argjson workspaces "$WORKSPACES" \
  --argjson visible "$VISIBLE" --argjson windows "$WINDOWS" \
  --arg focused "$FOCUSED_WORKSPACE" \
  --argjson compact "$COMPACT" \
  --argjson pinned '{"6":"6 Chat","7":"7 Calendar","8":"8 Email"}' '
  ($visible | map(.workspace)) as $active |
  ($windows | map(.workspace) | unique) as $occupied |
  ($monitors | sort_by(."monitor-id"))[] as $monitor |
  ($monitor."monitor-id" | tostring) as $id |
  (["group", "monitor." + $id,
    (if ($monitor."monitor-name" | test("built-in"; "i")) then "MAC"
     elif ($monitors | length) <= 2 then "EXT" else "D" + $id end),
    "on", "false", "false"] | @tsv),
  ($workspaces | map(select(."monitor-id" == $monitor."monitor-id")) |
    sort_by(.workspace | (tonumber? // .)) | .[] |
    .workspace as $ws |
    ["space", "space." + $ws,
     (if $compact then ({"6":"6 Chat","7":"7 Cal","8":"8 Mail"}[$ws] // $ws) else ($pinned[$ws] // $ws) end),
     (if (($pinned | has($ws)) or ($active | index($ws)) != null or ($occupied | index($ws)) != null or $ws == $focused)
      then "on" else "off" end),
     ($ws == $focused | tostring), (($active | index($ws)) != null | tostring)] | @tsv)
') || exit 0

item_exists() {
  case $'\n'"$ITEMS"$'\n' in *$'\n'"$1"$'\n'*) return 0 ;; *) return 1 ;; esac
}

ARGS=()
ORDER=()
while IFS=$'\t' read -r KIND ITEM LABEL DRAWING FOCUSED ACTIVE; do
  [ -n "$ITEM" ] || continue
  ORDER+=("$ITEM")
  if ! item_exists "$ITEM"; then
    ARGS+=(--add item "$ITEM" left)
  fi
  # Leave display associations unset: the bar itself follows the main display.
  ARGS+=(--set "$ITEM" drawing="$DRAWING" icon.drawing=off label="$LABEL")
  if [ "$KIND" = group ]; then
    ARGS+=(background.drawing=off label.font="$MONO_FONT:Medium:10.0"
      label.color="$MUTED_COLOR" padding_left=12 padding_right=4
      label.padding_left=0 label.padding_right=3)
  else
    # %q protects the workspace name when SketchyBar executes the click script.
    printf -v CLICK '%q workspace %q' "$CONFIG_DIR/plugins/toolbar.sh" "${ITEM#space.}"
    ARGS+=(background.height=23 background.corner_radius=5
      label.font="$MONO_FONT:Medium:12.0"
      padding_left=2 padding_right=2 label.padding_left=9 label.padding_right=9
      background.border_color="$BORDER_COLOR" background.border_width=0
      background.color="$ITEM_BG_COLOR" label.color="$MUTED_COLOR" click_script="$CLICK"
      background.drawing=off)
    if [ "$FOCUSED" = true ]; then
      ARGS+=(background.drawing=on background.color="$ACCENT_BG_COLOR"
        background.border_color="$ACCENT_BORDER_COLOR" background.border_width=1
        label.color="$ACCENT_COLOR")
    elif [ "$ACTIVE" = true ]; then
      ARGS+=(background.drawing=on background.border_width=1 label.color="$WHITE")
    fi
  fi
done <<< "$ROWS"

# Remove groups/workspaces that disappeared on disconnect, and old app lists.
DESIRED=$(printf '%s\n' "${ORDER[@]}")
while IFS= read -r ITEM; do
  case "$ITEM" in
    space.*|monitor.*)
      case $'\n'"$DESIRED"$'\n' in
        *$'\n'"$ITEM"$'\n'*) ;;
        *) ARGS+=(--remove "$ITEM") ;;
      esac ;;
  esac
done <<< "$ITEMS"

# The controls renderer owns visibility so an in-flight focus event cannot
# briefly reveal an app name after presentation mode has been enabled.
CACHE_DIR="$HOME/Library/Caches/AeroToolbar"
mkdir -p "$CACHE_DIR"
printf '%s' "$FOCUSED_APP" > "$CACHE_DIR/front_app.$$.tmp"
chmod 600 "$CACHE_DIR/front_app.$$.tmp"
mv "$CACHE_DIR/front_app.$$.tmp" "$CACHE_DIR/front_app.txt"
ARGS+=(--reorder "${ORDER[@]}" front_app)
sketchybar "${ARGS[@]}"
"$CONFIG_DIR/plugins/toolbar.sh" refresh
