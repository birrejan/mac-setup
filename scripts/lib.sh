#!/usr/bin/env bash
# Shared helpers — sourced by install.sh and every scripts/*.sh.
# Not meant to be executed directly.

# --- Paths -----------------------------------------------------------------
LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$LIB_DIR/.." && pwd)"
export REPO_ROOT

# --- Pretty logging --------------------------------------------------------
if [[ -t 1 ]]; then
  C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'; C_RED=$'\033[31m'; C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'; C_BLUE=$'\033[34m'; C_RESET=$'\033[0m'
else
  C_BOLD=""; C_DIM=""; C_RED=""; C_GREEN=""; C_YELLOW=""; C_BLUE=""; C_RESET=""
fi

log()  { printf '\n%s %s\n' "${C_BLUE}==>${C_RESET}" "${C_BOLD}$*${C_RESET}"; }
info() { printf '    %s\n' "$*"; }
ok()   { printf '    %s %s\n' "${C_GREEN}✓${C_RESET}" "$*"; }
warn() { printf '    %s %s\n' "${C_YELLOW}!${C_RESET}" "$*" >&2; }
err()  { printf '%s\n' "${C_RED}✗ $*${C_RESET}" >&2; }
skip() { printf '    %s %s\n' "${C_DIM}•${C_RESET}" "${C_DIM}$* (already done)${C_RESET}"; }

# --- Capabilities ----------------------------------------------------------
has() { command -v "$1" >/dev/null 2>&1; }

is_macos() { [[ "$(uname -s)" == "Darwin" ]]; }

# Homebrew prefix for this architecture.
brew_prefix() {
  if [[ -x /opt/homebrew/bin/brew ]]; then echo /opt/homebrew
  elif [[ -x /usr/local/bin/brew ]]; then echo /usr/local
  elif has brew; then dirname "$(dirname "$(command -v brew)")"
  else echo /opt/homebrew; fi
}

# Load brew into the current shell (no-op if not yet installed).
load_brew() {
  local prefix; prefix="$(brew_prefix)"
  if [[ -x "$prefix/bin/brew" ]]; then
    eval "$("$prefix/bin/brew" shellenv)"
  fi
}

# --- Interaction -----------------------------------------------------------
# Honors ASSUME_YES (exported by install.sh --yes). Returns 0 on yes.
confirm() {
  local prompt="${1:-Proceed?}" reply
  if [[ "${ASSUME_YES:-0}" == "1" ]]; then return 0; fi
  read -r -p "    ${prompt} [y/N] " reply || return 1
  [[ "$reply" =~ ^[Yy]$ ]]
}

# Move a path aside to a timestamped backup IF it is a real file/dir
# (not already a symlink we manage). Used before stowing.
backup_if_real() {
  local target="$1"
  if [[ -e "$target" && ! -L "$target" ]]; then
    local bak
    bak="${target}.bak-$(date +%Y%m%d%H%M%S)"
    mv "$target" "$bak"
    warn "backed up existing $(basename "$target") → $bak"
  fi
}
