#!/usr/bin/env bash
# Enable Touch ID for `sudo` in the terminal.
# Uses /etc/pam.d/sudo_local (macOS Sonoma+) so it survives OS updates.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

log "Touch ID for sudo"
is_macos || exit 0

TEMPLATE="/etc/pam.d/sudo_local.template"
TARGET="/etc/pam.d/sudo_local"

if grep -q "pam_tid.so" "$TARGET" 2>/dev/null; then
  skip "Touch ID for sudo"
  exit 0
fi

if ! confirm "Enable Touch ID for sudo? (asks for your password once to edit $TARGET)"; then
  warn "Skipped Touch ID for sudo."
  exit 0
fi

if [[ -f "$TEMPLATE" ]]; then
  # Copy the template and uncomment the pam_tid line.
  sudo sh -c "cp '$TEMPLATE' '$TARGET' && /usr/bin/sed -i '' 's/^#auth/auth/' '$TARGET'"
  if grep -q "pam_tid.so" "$TARGET" 2>/dev/null; then
    ok "Touch ID enabled (via $TARGET)"
    info "Test it: run 'sudo -k' then 'sudo true' in a NEW terminal — expect a fingerprint prompt."
  else
    warn "Wrote $TARGET but pam_tid line not found — check it manually."
  fi
else
  warn "No $TEMPLATE on this macOS. Add this line to the top of /etc/pam.d/sudo manually:"
  info "  auth       sufficient     pam_tid.so"
fi
