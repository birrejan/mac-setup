#!/usr/bin/env bash
# Git identity + GitHub username. Identity is written to ~/.gitconfig.local
# (never committed). The committed ~/.gitconfig includes that file.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

log "Git identity"
GITLOCAL="$HOME/.gitconfig.local"
[[ -f "$GITLOCAL" ]] || printf '%s\n' "# Local git identity — NOT tracked by the repo (see .gitignore)." > "$GITLOCAL"

# --- name + email ----------------------------------------------------------
if git config -f "$GITLOCAL" user.email >/dev/null 2>&1; then
  skip "identity ($(git config -f "$GITLOCAL" user.name 2>/dev/null) <$(git config -f "$GITLOCAL" user.email)>)"
elif [[ ! -t 0 ]]; then
  warn "Non-interactive — set it later: git config -f ~/.gitconfig.local user.email \"you@x.com\""
else
  read -r -p "    Git user name:  " git_name
  read -r -p "    Git user email: " git_email
  if [[ -n "$git_name" && -n "$git_email" ]]; then
    git config -f "$GITLOCAL" user.name  "$git_name"
    git config -f "$GITLOCAL" user.email "$git_email"
    ok "wrote identity to ~/.gitconfig.local"
  else
    warn "Empty name/email — skipped."
  fi
fi

# --- GitHub username (for github.user + this repo's push remote) -----------
# Default is detected from the repo's origin URL, if any.
default_gh="$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null \
  | sed -nE 's#.*github\.com[:/]([^/]+)/.*#\1#p' || true)"
default_gh="${default_gh:-$(git config -f "$GITLOCAL" github.user 2>/dev/null || true)}"

if [[ -t 0 ]]; then
  read -r -p "    GitHub username${default_gh:+ [$default_gh]} (blank to skip): " gh_user
  gh_user="${gh_user:-$default_gh}"
else
  gh_user="$default_gh"
fi

if [[ -n "$gh_user" ]]; then
  git config -f "$GITLOCAL" github.user "$gh_user"
  ok "GitHub username: $gh_user"

  # Point this repo's origin at SSH so you can push updates (e.g. after dump.sh).
  if git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    ssh_url="git@github.com:${gh_user}/$(basename "$REPO_ROOT").git"
    cur="$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null || true)"
    if [[ -z "$cur" ]]; then
      git -C "$REPO_ROOT" remote add origin "$ssh_url" && ok "set origin → $ssh_url"
    elif [[ "$cur" == https://github.com/* ]]; then
      git -C "$REPO_ROOT" remote set-url origin "$ssh_url" && ok "origin switched to SSH → $ssh_url"
    fi
  fi
fi
