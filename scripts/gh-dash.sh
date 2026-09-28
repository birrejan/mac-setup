#!/usr/bin/env bash
# gh-dash, built from the fork https://github.com/birrejan/gh-dash: upstream
# dlvhdr/gh-dash plus the changes merged on its `personal` branch. Installed as
# the `gh dash` extension. Re-runnable: an existing checkout is never touched.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

FORK="https://github.com/birrejan/gh-dash.git"
BRANCH="personal"
SRC="$HOME/.local/src/gh-dash"

log "gh-dash (birrejan/gh-dash, branch $BRANCH)"
load_brew
has gh || { err "gh is not installed (run scripts/homebrew.sh first)"; exit 1; }
has go || { err "go is not installed (run scripts/homebrew.sh first)"; exit 1; }

# A checkout you may be working in is left alone; update it yourself (see below).
if [[ -d "$SRC/.git" ]]; then
  skip "source at $SRC"
else
  mkdir -p "$(dirname "$SRC")"
  git clone --quiet --branch "$BRANCH" "$FORK" "$SRC"
  git -C "$SRC" remote add upstream https://github.com/dlvhdr/gh-dash.git
  ok "cloned $FORK ($BRANCH) → $SRC"
fi

if [[ -x "$SRC/gh-dash" ]]; then
  skip "binary $SRC/gh-dash"
else
  (cd "$SRC" && go build .)
  ok "built $SRC/gh-dash"
fi

# `gh extension list` needs a login; the extension's link on disk doesn't.
if [[ -e "${XDG_DATA_HOME:-$HOME/.local/share}/gh/extensions/gh-dash" ]]; then
  skip "gh dash extension"
else
  (cd "$SRC" && gh extension install .)
  ok "installed the gh dash extension from $SRC"
fi
info "Update later: cd $SRC && git pull && go build ."
