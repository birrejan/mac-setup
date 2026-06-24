#!/usr/bin/env bash
# mac-setup — provision a fresh Mac with one command.
#
#   ./install.sh                 # full setup (prompts where needed)
#   ./install.sh --yes           # assume "yes" to all confirmations
#   ./install.sh --skip-macos    # everything except the macOS defaults
#   ./install.sh --only ssh      # run a single step (preflight|homebrew|dotfiles|
#                                #   languages|git|ssh|vscode|iterm2|wm|macos|
#                                #   touchid|doctor|dump)
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

FAILED_STEPS=()
# Run a step. On failure, warn and keep going — never abort the whole install.
run() {
  local name="$1" rc=0
  bash "$ROOT/scripts/$name.sh" || rc=$?
  if (( rc != 0 )); then
    warn "step '$name' failed (exit $rc) — continuing"
    FAILED_STEPS+=("$name")
  fi
}

printf '%s\n' "${C_BOLD}╭────────────────────────────────────────╮${C_RESET}"
printf '%s\n' "${C_BOLD}│  mac-setup — provisioning this Mac      │${C_RESET}"
printf '%s\n' "${C_BOLD}╰────────────────────────────────────────╯${C_RESET}"

if [[ -n "$ONLY" ]]; then
  [[ -f "$ROOT/scripts/$ONLY.sh" ]] || { err "No such step: $ONLY"; exit 1; }
  exec bash "$ROOT/scripts/$ONLY.sh"   # single step: preserve its real exit code
fi

run preflight
run homebrew
run dotfiles
run languages
run git
run ssh
run vscode
run iterm2
run wm
if [[ "$SKIP_MACOS" == "0" ]]; then run macos; else warn "Skipping macOS tweaks (--skip-macos)"; fi
run touchid

# Healthcheck — report only; never counts as a failed install step.
bash "$ROOT/scripts/doctor.sh" || true

if (( ${#FAILED_STEPS[@]} )); then
  warn "Finished with issues in: ${FAILED_STEPS[*]}"
  warn "Re-run any of them individually, e.g.: ./install.sh --only ${FAILED_STEPS[0]}"
fi

log "All done 🎉  — manual follow-ups"
cat <<'EOF'
    1. Restart your terminal (or: exec zsh) to load the new shell config.
    2. Add the printed SSH key to GitHub (Authentication + Signing).
    3. Grant Accessibility permissions: AeroSpace, Rectangle, Raycast, Alfred.
    4. Sign in to your apps: Proton, Slack, Claude, Alfred, Superwhisper, Yubico.
    5. Verify a signed commit shows "Verified" on GitHub after step 2.

    Re-check anytime:  ./install.sh --only doctor
    Extra tooling:     brew bundle --file=Brewfile.optional
EOF
