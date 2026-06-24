#!/usr/bin/env bash
# Link VS Code settings/keybindings and install the extension list.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

log "VS Code"

if ! has code; then
  warn "'code' CLI not found."
  info "Open VS Code → Cmd+Shift+P → \"Shell Command: Install 'code' command in PATH\", then re-run:"
  info "  ./install.sh --only vscode"
  exit 0
fi

USER_DIR="$HOME/Library/Application Support/Code/User"
mkdir -p "$USER_DIR"

for f in settings.json keybindings.json; do
  src="$REPO_ROOT/vscode/$f"
  dst="$USER_DIR/$f"
  [[ -f "$src" ]] || continue
  backup_if_real "$dst"
  ln -sfn "$src" "$dst"
  ok "linked $f"
done

EXT_FILE="$REPO_ROOT/vscode/extensions.txt"
if [[ -f "$EXT_FILE" ]]; then
  info "Installing extensions…"
  installed="$(code --list-extensions 2>/dev/null || true)"
  while IFS= read -r ext || [[ -n "$ext" ]]; do
    ext="${ext%%#*}"; ext="$(echo "$ext" | tr -d '[:space:]')"
    [[ -z "$ext" ]] && continue
    if grep -qix "$ext" <<<"$installed"; then
      skip "$ext"
    elif code --install-extension "$ext" --force >/dev/null 2>&1; then
      ok "$ext"
    else
      warn "failed: $ext"
    fi
  done < "$EXT_FILE"
fi

ok "VS Code configured"
