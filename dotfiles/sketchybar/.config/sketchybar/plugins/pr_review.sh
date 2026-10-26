#!/bin/bash

# The REVIEW pill, for a Claude review that `pr-review ai` is running or has
# finished. It reads the status file the review keeps in pr-review's cache.
#
#   running   #882 7m · Read prrow.go   just "#882 7m" on the compact bar or
#                                       in presentation mode
#   finished  #882 3 comments           on a surface, until it is clicked or the
#                                       review is submitted with pr-review
#   failed    #882 failed               in red, until it is clicked
#
# A click on a running review follows its log in a new iTerm window. A click on a
# finished one opens the PR's files on GitHub, where the comments wait in your
# pending review to be edited and submitted, and dismisses it. A click on a
# failed one opens its log and dismisses it. With several reviews, the pill
# shows the newest running one, else the newest finished one, plus "+N".

source "$CONFIG_DIR/helpers.sh"

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/pr-review"
TOOLBAR_DATA="$HOME/Library/Application Support/AeroToolbar"
US=$'\x1f'

# Sets SHOWN to the status file to show, and STATE, NWO, PR, LOG, STARTED,
# ACTIVITY, POSTED and COUNT from it. A review whose process is gone without
# finishing counts as failed.
pick() {
  local file state pid nwo pr log started activity posted rank shown_rank=0
  SHOWN="" COUNT=0 STARTED=0
  for file in "$CACHE"/*-ai.json; do
    [ -f "$file" ] || continue
    IFS=$US read -r state pid nwo pr log started activity posted < <(
      jq -r '[.state, .pid, .nwo, .pr, .log, .started, .activity, .posted]
        | map(. // "" | tostring) | join("\u001f")' "$file" 2>/dev/null)
    [ -n "$state" ] || continue

    rank=1
    case $state in
      preparing | reviewing | posting)
        if kill -0 "$pid" 2>/dev/null; then rank=2; else state=failed; fi
        ;;
    esac

    COUNT=$((COUNT + 1))
    if [ "$rank" -gt "$shown_rank" ] || { [ "$rank" -eq "$shown_rank" ] && [ "${started:-0}" -gt "$STARTED" ]; }; then
      shown_rank=$rank SHOWN=$file STATE=$state NWO=$nwo PR=$pr LOG=$log
      STARTED=${started:-0} ACTIVITY=$activity POSTED=${posted:-0}
    fi
  done
}

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

pick

if [ "$SENDER" = "mouse.clicked" ] && [ -n "$SHOWN" ]; then
  case $STATE in
    preparing | reviewing | posting)
      open_in_iterm "/usr/bin/tail -n +1 -F $LOG"
      ;;
    done)
      open "https://github.com/$NWO/pull/$PR/files"
      rm -f "$SHOWN"
      ;;
    *)
      open_in_iterm "/usr/bin/less +G $LOG"
      rm -f "$SHOWN"
      ;;
  esac
  pick
fi

if [ -z "$SHOWN" ]; then
  sketchybar --set "$NAME" drawing=off
  exit 0
fi

# The compact bar has no room for the step, and presentation mode hides it,
# since file names are as private as the window titles it already hides.
BRIEF=0
if [ -e "$TOOLBAR_DATA/compact" ] || [ -e "$TOOLBAR_DATA/presentation" ]; then
  BRIEF=1
fi

ELAPSED=$(($(date +%s) - STARTED))
if [ "$ELAPSED" -lt 60 ]; then
  ELAPSED="${ELAPSED}s"
else
  ELAPSED="$((ELAPSED / 60))m"
fi

# SURFACE goes last when it is set: setting a background color turns it on.
COLOR=$WHITE ICON_COLOR=$ACCENT_COLOR SURFACE=off
case $STATE in
  preparing)
    LABEL="#$PR starting"
    ;;
  reviewing | posting)
    LABEL="#$PR $ELAPSED"
    [ "$STATE" = posting ] && ACTIVITY="posting comments"
    if [ "$BRIEF" = 0 ] && [ -n "$ACTIVITY" ]; then
      LABEL="$LABEL · ${ACTIVITY:0:32}"
    fi
    ;;
  done)
    SURFACE=on
    if [ "$BRIEF" = 1 ]; then
      LABEL="#$PR ✓$([ "$POSTED" -gt 0 ] && echo "$POSTED")"
    elif [ "$POSTED" -eq 0 ]; then
      LABEL="#$PR nothing found"
    elif [ "$POSTED" -eq 1 ]; then
      LABEL="#$PR 1 comment"
    else
      LABEL="#$PR $POSTED comments"
    fi
    ;;
  *)
    LABEL="#$PR failed" COLOR=$CRIT_COLOR ICON_COLOR=$CRIT_COLOR
    ;;
esac
[ "$COUNT" -gt 1 ] && LABEL="$LABEL +$((COUNT - 1))"

sketchybar --set "$NAME" drawing=on \
                        label="$LABEL" \
                        label.color="$COLOR" \
                        icon.color="$ICON_COLOR" \
                        background.color="$ACCENT_BG_COLOR" \
                        background.border_color="$ACCENT_BORDER_COLOR" \
                        background.border_width=1 \
                        background.drawing="$SURFACE"
