#!/usr/bin/env bash
# One-line bootstrap for a brand-new Mac. Run:
#
#   bash <(curl -fsSL https://raw.githubusercontent.com/<your-username>/mac-setup/main/bootstrap.sh)
#
# Installs the Xcode Command Line Tools, clones this repo, and runs install.sh.
# Override the source/destination with env vars if needed:
#   MACSETUP_REPO=https://github.com/you/mac-setup.git MACSETUP_DIR=~/code/mac-setup bash <(curl ...)
set -euo pipefail

REPO_URL="${MACSETUP_REPO:-https://github.com/<your-username>/mac-setup.git}"
DEST="${MACSETUP_DIR:-$HOME/mac-setup}"

echo "==> mac-setup bootstrap"

# 1. Xcode Command Line Tools (provides git + compilers).
if ! xcode-select -p >/dev/null 2>&1; then
  echo "==> Installing Xcode Command Line Tools — click \"Install\" in the dialog…"
  xcode-select --install || true
  echo "==> Waiting for the Command Line Tools to finish installing…"
  until xcode-select -p >/dev/null 2>&1; do sleep 10; done
fi

# 2. Clone (or fast-forward) the repo.
if [[ -d "$DEST/.git" ]]; then
  echo "==> Updating existing clone at $DEST"
  git -C "$DEST" pull --ff-only || true
else
  echo "==> Cloning $REPO_URL → $DEST"
  git clone "$REPO_URL" "$DEST"
fi

# 3. Hand off to the installer. Using exec keeps the terminal attached so the
#    interactive prompts (git identity, confirmations) work.
cd "$DEST"
exec ./install.sh "$@"
