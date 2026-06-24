#!/usr/bin/env bash
# Install Homebrew (if missing) and install everything in the Brewfile.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

log "Homebrew"

if has brew || [[ -x "$(brew_prefix)/bin/brew" ]]; then
  skip "Homebrew install"
else
  info "Installing Homebrew…"
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ok "Homebrew installed"
fi

load_brew
has brew || { err "brew not on PATH after install"; exit 1; }

info "Updating Homebrew…"
brew update --quiet || warn "brew update reported issues (continuing)"

log "Installing apps & tools from Brewfile (this can take a while)"
brew bundle --file="$REPO_ROOT/Brewfile"
ok "Brewfile complete"

info "Tip: enable extra tooling later with: brew bundle --file=$REPO_ROOT/Brewfile.optional"
