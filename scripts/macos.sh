#!/usr/bin/env bash
# Apply sensible, reversible macOS defaults. Every block notes what it does.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

log "macOS system preferences"
is_macos || { warn "Not macOS — skipping"; exit 0; }

if ! confirm "Apply macOS tweaks (keyboard, trackpad, Finder, Dock, screenshots, dark mode)?"; then
  warn "Skipped macOS tweaks."
  exit 0
fi

# Close System Settings so it doesn't override what we write.
osascript -e 'tell application "System Settings" to quit' >/dev/null 2>&1 || true

# --- Keyboard: fast key repeat, no press-and-hold accent menu -------------
defaults write -g KeyRepeat -int 2          # revert: defaults delete -g KeyRepeat
defaults write -g InitialKeyRepeat -int 15  # revert: defaults delete -g InitialKeyRepeat
defaults write -g ApplePressAndHold -bool false

# --- Trackpad: tap to click ------------------------------------------------
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
defaults -currentHost write -g com.apple.mouse.tapBehavior -int 1
defaults write -g com.apple.mouse.tapBehavior -int 1

# --- Appearance: dark mode -------------------------------------------------
defaults write -g AppleInterfaceStyle -string "Dark"   # revert: defaults delete -g AppleInterfaceStyle

# --- Finder ----------------------------------------------------------------
defaults write NSGlobalDomain AppleShowAllExtensions -bool true
defaults write com.apple.finder AppleShowAllFiles -bool true        # show hidden files
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder _FXShowPosixPathInTitle -bool true
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv" # list view
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf" # search current folder
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# --- Screenshots → ~/Screenshots, PNG, no window shadow --------------------
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"
defaults write com.apple.screencapture type -string "png"
defaults write com.apple.screencapture disable-shadow -bool true

# --- Dock: small, autohide, no recents, stable spaces (good for tiling) ----
defaults write com.apple.dock tilesize -int 42
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mru-spaces -bool false   # don't auto-rearrange Spaces

# --- Dialogs: expand save/print panels, default to disk (not iCloud) -------
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

killall Finder Dock SystemUIServer 2>/dev/null || true
ok "macOS preferences applied (a few changes take effect after logout/restart)"
