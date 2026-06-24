#!/usr/bin/env bash
# Generate an ed25519 SSH key, wire it into the agent + macOS Keychain,
# set up SSH-based commit signing, and print the public key for GitHub.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

log "SSH key & commit signing"

SSH_DIR="$HOME/.ssh"
KEY="$SSH_DIR/id_ed25519"
mkdir -p "$SSH_DIR"; chmod 700 "$SSH_DIR"

email="$(git config user.email 2>/dev/null || true)"
[[ -z "$email" ]] && email="$(whoami)@$(scutil --get LocalHostName 2>/dev/null || hostname)"

if [[ -f "$KEY" ]]; then
  skip "SSH key ($KEY)"
else
  info "Generating ed25519 key for <$email> (empty passphrase; change later with: ssh-keygen -p -f $KEY)"
  ssh-keygen -t ed25519 -C "$email" -f "$KEY" -N ""
  ok "Key generated"
fi

# ssh config: load into agent + store passphrase in Keychain
CONF="$SSH_DIR/config"
if ! grep -q "id_ed25519" "$CONF" 2>/dev/null; then
  cat >> "$CONF" <<'EOF'

Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
  chmod 600 "$CONF"
  ok "Wrote ~/.ssh/config (agent + Keychain)"
else
  skip "ssh config"
fi

ssh-add --apple-use-keychain "$KEY" >/dev/null 2>&1 || true

# allowed_signers — lets `git log --show-signature` verify your own commits locally.
mkdir -p "$HOME/.config/git"
SIGNERS="$HOME/.config/git/allowed_signers"
PUB="$(cat "$KEY.pub")"
if ! grep -qF "$PUB" "$SIGNERS" 2>/dev/null; then
  printf '%s %s\n' "$email" "$PUB" > "$SIGNERS"
  ok "Wrote allowed_signers"
else
  skip "allowed_signers"
fi

log "ACTION REQUIRED — add this key to GitHub (as BOTH types)"
info "Web: Settings → SSH and GPG keys → New SSH key — add the key twice:"
info "  • Authentication Key   (lets you push/pull over SSH)"
info "  • Signing Key          (makes your commits show as Verified)"
echo
printf '%s\n' "$PUB"
echo
info "Or with the GitHub CLI:"
info "  gh auth login"
info "  gh ssh-key add ~/.ssh/id_ed25519.pub --type authentication --title \"$(hostname)\""
info "  gh ssh-key add ~/.ssh/id_ed25519.pub --type signing        --title \"$(hostname) signing\""
