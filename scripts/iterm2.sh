#!/usr/bin/env bash
# Configure iTerm2: install the versioned Dynamic Profile (font + One Dark theme)
# and make it the default. No manual GUI steps required.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

log "iTerm2"

if [[ ! -d "/Applications/iTerm.app" ]]; then
  warn "iTerm2 not installed yet (Brewfile step installs it) — skipping."
  exit 0
fi

DP_DIR="$HOME/Library/Application Support/iTerm2/DynamicProfiles"
mkdir -p "$DP_DIR"

src="$REPO_ROOT/iterm2/DynamicProfiles/mac-setup.json"
dst="$DP_DIR/mac-setup.json"
backup_if_real "$dst"
ln -sfn "$src" "$dst"
ok "Installed dynamic profile (font: Hack Nerd Font Mono, theme: One Dark)"

# Make "mac-setup" the default profile (matches the Guid in the JSON).
defaults write com.googlecode.iterm2 "Default Bookmark Guid" -string "mac-setup-0001" 2>/dev/null || true
# Don't prompt to quit, and don't show the "new version" nag.
defaults write com.googlecode.iterm2 PromptOnQuit -bool false 2>/dev/null || true

ok "iTerm2 configured"
info "If iTerm2 is open, restart it (the profile loads on launch)."
