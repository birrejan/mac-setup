#!/usr/bin/env bash
# Symlink dotfiles into $HOME with GNU Stow. Re-runnable.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

log "Dotfiles (GNU Stow)"
load_brew
has stow || { err "stow is not installed (run scripts/homebrew.sh first)"; exit 1; }

PACKAGES=(zsh git starship mise aerospace sketchybar)

# Back up any pre-existing REAL files that would collide, so stow won't refuse.
for pkg in "${PACKAGES[@]}"; do
  pkgdir="$REPO_ROOT/dotfiles/$pkg"
  [[ -d "$pkgdir" ]] || continue
  while IFS= read -r -d '' f; do
    rel="${f#"$pkgdir"/}"
    backup_if_real "$HOME/$rel"
  done < <(find "$pkgdir" -type f -print0)
done

# --restow makes this idempotent (remove then re-link).
stow --dir="$REPO_ROOT/dotfiles" --target="$HOME" --restow "${PACKAGES[@]}"
ok "Linked: ${PACKAGES[*]}"
info "Each ~ file is now a symlink into $REPO_ROOT/dotfiles — edit in the repo, changes apply live."
