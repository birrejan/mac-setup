#!/usr/bin/env bash
# Preflight: assert macOS, report architecture, ensure Xcode Command Line Tools.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

log "Preflight checks"

if ! is_macos; then
  err "This setup is for macOS only (detected $(uname -s))."
  exit 1
fi

# Architecture / brew prefix
arch="$(uname -m)"
info "macOS $(sw_vers -productVersion) on ${arch} (brew prefix: $(brew_prefix))"

# Xcode Command Line Tools — required for git, compilers, and Homebrew.
if xcode-select -p >/dev/null 2>&1; then
  skip "Xcode Command Line Tools"
else
  log "Installing Xcode Command Line Tools"
  info "A system dialog will appear — click \"Install\" and accept the license."
  xcode-select --install || true
  info "Waiting for the Command Line Tools installation to finish…"
  until xcode-select -p >/dev/null 2>&1; do sleep 10; done
  ok "Xcode Command Line Tools installed"
fi
