#!/usr/bin/env bash
# Set the single git identity into ~/.gitconfig.local (never committed).
# The committed ~/.gitconfig includes this file.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

log "Git identity"
GITLOCAL="$HOME/.gitconfig.local"

if [[ -f "$GITLOCAL" ]] && git config -f "$GITLOCAL" user.email >/dev/null 2>&1; then
  skip "Git identity ($(git config -f "$GITLOCAL" user.name 2>/dev/null) <$(git config -f "$GITLOCAL" user.email)>)"
  exit 0
fi

if [[ ! -t 0 ]]; then
  warn "Non-interactive shell — set your identity later with:"
  info "  git config -f ~/.gitconfig.local user.name  \"Your Name\""
  info "  git config -f ~/.gitconfig.local user.email \"you@example.com\""
  exit 0
fi

read -r -p "    Git user name:  " git_name
read -r -p "    Git user email: " git_email

if [[ -z "$git_name" || -z "$git_email" ]]; then
  warn "Empty name/email — skipping. Set it later in ~/.gitconfig.local"
  exit 0
fi

# NOTE: git config wants tab-indented values; tabs below are intentional.
cat > "$GITLOCAL" <<EOF
# Local git identity — NOT tracked by the dotfiles repo (see .gitignore).
[user]
	name = ${git_name}
	email = ${git_email}
EOF

ok "Wrote $GITLOCAL"
