#!/bin/bash

# Clicked from the cpu / memory cards: opens btop in a new iTerm window, so the
# card is a way in to the tool rather than just a number.
osascript -e 'tell application "iTerm" to create window with default profile command "btop"' >/dev/null 2>&1
osascript -e 'tell application "iTerm" to activate' >/dev/null 2>&1
