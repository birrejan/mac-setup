#!/bin/bash

# The TASK pill, for Taskwarrior. It is drawn only while something needs you today:
#
#   started    Review inspace-app#882 · 25m   the task you `task <id> start`ed, and
#                                             for how long; +N if more are started
#   overdue    2 overdue                      in red, on a surface
#   due today  11:00 Prepare CSMxProduct …    the next one due; +N for the others
#
# Amber means a task falls due within the hour and red that one is overdue: the
# label says so when nothing is started, the icon does while one is. Presentation
# mode hides the descriptions, as it hides other titles, and the compact bar
# shortens them. A click opens taskwarrior-tui in a new iTerm window.

source "$CONFIG_DIR/helpers.sh"

TOOLBAR_DATA="$HOME/Library/Application Support/AeroToolbar"
US=$'\x1f'

# Runs a command in a new iTerm window, like the cpu card's btop.
open_in_iterm() {
  osascript - "$1" >/dev/null 2>&1 <<'APPLESCRIPT'
on run argv
  tell application "iTerm"
    create window with default profile command (item 1 of argv)
    activate
  end tell
end run
APPLESCRIPT
}

if [ "$SENDER" = "mouse.clicked" ]; then
  # Through an interactive login zsh, so PATH is a normal tab's and the TUI's
  # 1 key finds task-open's tools.
  open_in_iterm "/bin/zsh -lic taskwarrior-tui"
  exit 0
fi

MAX=28
[ -e "$TOOLBAR_DATA/compact" ] && MAX=14
PRESENTING=0
[ -e "$TOOLBAR_DATA/presentation" ] && PRESENTING=1
NOW=$(date +%s)

# rc.hooks=0 so reading never fires task_change again, and rc.gc=0 so the bar
# never renumbers tasks under a list you are reading. jq trims the descriptions,
# since it counts characters where bash would count bytes.
STATE=$(task rc.verbose=nothing rc.hooks=0 rc.gc=0 \
    +PENDING -WAITING '( +ACTIVE or due.before:tomorrow )' export 2>/dev/null |
  jq -r --argjson now "$NOW" --argjson max "$MAX" '
    def epoch: strptime("%Y%m%dT%H%M%SZ") | mktime;
    def short: if length > $max then .[0:$max - 1] + "…" else . end;
    (map(select(.start)) | sort_by(-.urgency)) as $started
    | (map(select(.due) | .due_at = (.due | epoch)) | sort_by(.due_at)) as $dated
    | ($dated | map(select(.due_at < $now))) as $overdue
    | ($dated | map(select(.due_at >= $now))) as $due
    | [ ($started | length),
        ($started[0].description // "" | short),
        ($started[0].start // null | if . then epoch else 0 end),
        ($overdue | length),
        ($due | length),
        ($due[0].description // "" | short),
        ($due[0].due_at // 0) ]
    | map(tostring) | join("\u001f")' 2>/dev/null)

IFS=$US read -r STARTED DESC START_AT OVERDUE DUE DUE_DESC DUE_AT <<< "$STATE"

if [ -z "$STARTED" ] || [ $((STARTED + OVERDUE + DUE)) -eq 0 ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

# 25m, or 1h05 past the hour.
duration() {
  if [ "$1" -lt 3600 ]; then
    echo "$(($1 / 60))m"
  else
    printf '%dh%02d\n' $(($1 / 3600)) $(($1 % 3600 / 60))
  fi
}

SOON=0
[ "$DUE" -gt 0 ] && [ $((DUE_AT - NOW)) -le 3600 ] && SOON=1

LABEL_COLOR=$WHITE ICON_COLOR=$ACCENT_COLOR SURFACE=off
if [ "$STARTED" -gt 0 ]; then
  LABEL=$(duration $((NOW - START_AT)))
  [ "$PRESENTING" = 0 ] && LABEL="$DESC · $LABEL"
  [ "$STARTED" -gt 1 ] && LABEL="$LABEL +$((STARTED - 1))"
  if [ "$OVERDUE" -gt 0 ]; then
    ICON_COLOR=$CRIT_COLOR
  elif [ "$SOON" = 1 ]; then
    ICON_COLOR=$WARN_COLOR
  fi
elif [ "$OVERDUE" -gt 0 ]; then
  LABEL="$OVERDUE overdue" LABEL_COLOR=$CRIT_COLOR ICON_COLOR=$CRIT_COLOR SURFACE=on
else
  LABEL=$(date -r "$DUE_AT" +%H:%M)
  [ "$PRESENTING" = 0 ] && LABEL="$LABEL $DUE_DESC"
  [ "$DUE" -gt 1 ] && LABEL="$LABEL +$((DUE - 1))"
  [ "$SOON" = 1 ] && LABEL_COLOR=$WARN_COLOR ICON_COLOR=$WARN_COLOR
fi

sketchybar --set "$NAME" drawing=on \
                        label="$LABEL" \
                        label.color="$LABEL_COLOR" \
                        icon.color="$ICON_COLOR" \
                        background.drawing="$SURFACE"
