#!/usr/bin/env bash
# Install language runtimes via mise (Node + Python), enable corepack.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

log "Languages (mise)"
load_brew
has mise || { warn "mise not installed; skipping languages"; exit 0; }

# Activate mise for this non-interactive shell.
eval "$(mise activate bash)" 2>/dev/null || true

if [[ -f "$HOME/.config/mise/config.toml" ]]; then
  info "Installing runtimes declared in ~/.config/mise/config.toml…"
  mise install
else
  warn "No mise config found (dotfiles not stowed yet?) — installing sane defaults."
  mise use -g node@lts python@3.13
fi

# Enable corepack so pnpm/yarn are available without a global npm install.
if mise which node >/dev/null 2>&1 || has node; then
  mise exec -- corepack enable >/dev/null 2>&1 \
    || corepack enable >/dev/null 2>&1 \
    || warn "corepack enable failed (enable manually if you need pnpm/yarn)"
fi

info "Active runtimes:"
mise current 2>/dev/null || true
ok "Languages ready"
