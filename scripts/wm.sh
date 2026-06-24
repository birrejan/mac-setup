#!/usr/bin/env bash
# Finalize the AeroSpace (tiling WM) + SketchyBar (custom menu bar) stack.
set -euo pipefail
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib.sh"

log "Window manager + menu bar (AeroSpace + SketchyBar)"
load_brew

# Captured plugin/item scripts must be executable for SketchyBar to run them.
if [[ -d "$HOME/.config/sketchybar" ]]; then
  find "$HOME/.config/sketchybar" -name '*.sh' -exec chmod +x {} + 2>/dev/null || true
  [[ -f "$HOME/.config/sketchybar/sketchybarrc" ]] && chmod +x "$HOME/.config/sketchybar/sketchybarrc" || true
  ok "SketchyBar scripts made executable"
fi

# Start SketchyBar as a background brew service (AeroSpace also does this at login).
if has sketchybar; then
  if brew services start sketchybar >/dev/null 2>&1 || brew services restart sketchybar >/dev/null 2>&1; then
    ok "SketchyBar service running"
  else
    warn "Could not start SketchyBar service (try: brew services start sketchybar)"
  fi
fi

# Launch AeroSpace (its config sets start-at-login = true for future boots).
if [[ -d "/Applications/AeroSpace.app" ]]; then
  open -a AeroSpace >/dev/null 2>&1 || true
  ok "AeroSpace launched"
fi

log "ACTION REQUIRED — grant Accessibility permissions"
info "System Settings → Privacy & Security → Accessibility — enable:"
info "  • AeroSpace   (required: window management won't work without it)"
info "  • Rectangle   (window snapping)"
info "  • Raycast     (window management / global hotkeys)"
info "  • Alfred      (global hotkeys / automation)"
info "Each app will also prompt you on first launch."
