#!/usr/bin/env bash
# One-line bootstrap for a brand-new Mac. Run (replace GH with your handle):
#
#   GH=<your-username>; bash <(curl -fsSL "https://raw.githubusercontent.com/$GH/mac-setup/main/bootstrap.sh")
#
# Installs the Xcode Command Line Tools, clones this repo, and runs install.sh.
# The GitHub username/repo are asked interactively (nothing is hardcoded).
# Skip the prompts by exporting them up front:
#   MACSETUP_REPO=https://github.com/you/mac-setup.git MACSETUP_DIR=~/code/mac-setup bash <(curl ...)
set -euo pipefail

DEST="${MACSETUP_DIR:-$HOME/mac-setup}"
REPO_URL="${MACSETUP_REPO:-}"

echo "==> mac-setup bootstrap"

# Ask for the repo location if not supplied via env (keeps the username un-hardcoded).
if [[ -z "$REPO_URL" ]]; then
  read -r -p "GitHub username: " gh_user
  read -r -p "Repo name [mac-setup]: " gh_repo
  gh_repo="${gh_repo:-mac-setup}"
  if [[ -z "$gh_user" ]]; then echo "GitHub username is required." >&2; exit 1; fi
  REPO_URL="https://github.com/${gh_user}/${gh_repo}.git"
fi
echo "==> Using repo: $REPO_URL"

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
