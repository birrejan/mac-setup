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

# Homebrew 6+ refuses formulae/casks from untrusted third-party taps
# (when HOMEBREW_REQUIRE_TAP_TRUST is enforced). Trust ours up front.
log "Trusting third-party taps"
for t in nikitabobko/tap felixkratz/formulae; do
  brew tap "$t" >/dev/null 2>&1 || true
  if brew trust --tap "$t" >/dev/null 2>&1; then
    ok "trusted $t"
  else
    warn "could not trust $t — its formula/cask may be skipped"
  fi
done

log "Installing apps & tools from Brewfile (this can take a while)"
if brew bundle --file="$REPO_ROOT/Brewfile"; then
  ok "Brewfile complete"
else
  warn "Some Brewfile entries failed (see above) — continuing with the rest of setup."
fi

info "Tip: enable extra tooling later with: brew bundle --file=$REPO_ROOT/Brewfile.optional"
