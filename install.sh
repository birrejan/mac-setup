#!/usr/bin/env bash
# mac-setup — provision a fresh Mac with one command.
#
#   ./install.sh                 # full setup (prompts where needed)
#   ./install.sh --yes           # assume "yes" to all confirmations
#   ./install.sh --skip-macos    # everything except the macOS defaults
#   ./install.sh --only ssh      # run a single step (preflight|homebrew|dotfiles|
#                                #   languages|git|ssh|vscode|wm|macos)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$ROOT/scripts/lib.sh"

ASSUME_YES=0
SKIP_MACOS=0
ONLY=""

usage() { sed -n '2,9p' "$ROOT/install.sh" | sed 's/^# \{0,1\}//'; }

while [[ $# -gt 0 ]]; do
  case "$1" in
    -y|--yes)      ASSUME_YES=1 ;;
    --skip-macos)  SKIP_MACOS=1 ;;
    --only)        ONLY="${2:-}"; shift ;;
    -h|--help)     usage; exit 0 ;;
    *)             err "Unknown option: $1"; usage; exit 1 ;;
  esac
  shift
done
export ASSUME_YES

run() { bash "$ROOT/scripts/$1.sh"; }

printf '%s\n' "${C_BOLD}╭────────────────────────────────────────╮${C_RESET}"
printf '%s\n' "${C_BOLD}│  mac-setup — provisioning this Mac      │${C_RESET}"
printf '%s\n' "${C_BOLD}╰────────────────────────────────────────╯${C_RESET}"

if [[ -n "$ONLY" ]]; then
  [[ -f "$ROOT/scripts/$ONLY.sh" ]] || { err "No such step: $ONLY"; exit 1; }
  run "$ONLY"
  exit 0
fi

run preflight
run homebrew
run dotfiles
run languages
run git
run ssh
run vscode
run wm
if [[ "$SKIP_MACOS" == "0" ]]; then run macos; else warn "Skipping macOS tweaks (--skip-macos)"; fi

log "All done 🎉  — manual follow-ups"
cat <<'EOF'
    1. Restart your terminal (or: exec zsh) to load the new shell config.
    2. Add the printed SSH key to GitHub (Authentication + Signing).
    3. Grant Accessibility permissions: AeroSpace, Rectangle, Raycast, Alfred.
    4. iTerm2: set the font to "Hack Nerd Font Mono" and import a color preset.
    5. Sign in to your apps: Proton, Slack, Claude, Alfred, Superwhisper, Yubico.
    6. Verify a signed commit shows "Verified" on GitHub after step 2.

    Enable extra tooling any time:  brew bundle --file=Brewfile.optional
EOF
