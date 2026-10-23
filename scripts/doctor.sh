#!/usr/bin/env bash
# Healthcheck — verify the machine is fully provisioned. Read-only.
# Run directly (./scripts/doctor.sh) or via ./install.sh --only doctor
set -uo pipefail   # NOT -e: we want to run every check and total the failures.
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

fails=0
pass() { ok "$1"; }
fail() { printf '    %s %s\n' "${C_RED}✗${C_RESET}" "$1" >&2; fails=$((fails+1)); }
check() { local d="$1"; shift; if "$@" >/dev/null 2>&1; then pass "$d"; else fail "$d"; fi; }

log "Doctor — verifying setup"
load_brew

log "CLI tools"
for c in brew git gh lazygit delta difft go stow starship mise uv fzf rg fd bat eza zoxide jq task taskwarrior-tui code; do
  if has "$c"; then pass "$c"; else fail "$c (missing)"; fi
done

log "Runtimes"
check "node available"   bash -c 'mise which node   2>/dev/null || command -v node'
check "python available" bash -c 'mise which python 2>/dev/null || command -v python3'

log "Dotfiles (should resolve into the repo)"
# Stow links a whole directory when it can (e.g. ~/.config/sketchybar), so a
# file is managed if its resolved path is inside dotfiles/, whichever part of
# the path is the symlink.
dotfiles_dir="$(realpath "$REPO_ROOT/dotfiles")"
for f in .zshrc .zshenv .gitconfig .gitignore_global \
         .config/starship.toml .config/mise/config.toml \
         .config/aerospace/aerospace.toml .config/sketchybar/sketchybarrc \
         .config/lazygit/config.yml .config/gh-dash/config.yml .config/task/taskrc \
         .local/bin/pr-review .local/bin/task-open; do
  if [[ "$(realpath "$HOME/$f" 2>/dev/null)" == "$dotfiles_dir"/* ]]; then pass "$f"
  elif [[ -e "$HOME/$f" ]]; then fail "$f (exists but isn't linked into the repo)"
  else fail "$f (missing)"; fi
done

log "Git & SSH"
check "git identity set"        bash -c 'git config user.email'
check "gh dash extension"       test -e "${XDG_DATA_HOME:-$HOME/.local/share}/gh/extensions/gh-dash"
if [[ "$(git config --get commit.gpgsign 2>/dev/null)" == "true" ]]; then
  pass "commit signing enabled"
else
  fail "commit signing enabled"
fi
check "ssh key present"         test -f "$HOME/.ssh/id_ed25519"
check "allowed_signers present" test -f "$HOME/.config/git/allowed_signers"

log "Window manager / menu bar"
check "AeroSpace installed"  test -d "/Applications/AeroSpace.app"
check "sketchybar running"   bash -c "brew services list 2>/dev/null | grep -Eq 'sketchybar.*(started|none.*started)|sketchybar +started'"

log "Apps"
shopt -s nullglob nocaseglob
for app in "iTerm" "Visual Studio Code" "Alfred" "Claude" "Superwhisper" "Yubico Authenticator" "Slack"; do
  matches=(/Applications/"${app}"*.app)
  if (( ${#matches[@]} )); then pass "$app"; else fail "$app (missing)"; fi
done
shopt -u nocaseglob nullglob

log "Extras"
check "Touch ID for sudo"  bash -c 'grep -q pam_tid.so /etc/pam.d/sudo_local 2>/dev/null'
check "iTerm2 profile"     test -e "$HOME/Library/Application Support/iTerm2/DynamicProfiles/mac-setup.json"

echo
if [[ "$fails" -eq 0 ]]; then
  ok "All checks passed 🎉"
  exit 0
else
  warn "$fails check(s) failed — review the ✗ lines above."
  exit 1
fi
