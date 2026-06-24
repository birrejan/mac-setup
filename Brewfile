# Brewfile — the single source of truth for everything Homebrew installs.
# Run with:  brew bundle --file=Brewfile
# Re-runnable and idempotent: already-installed items are skipped.

# ---------------------------------------------------------------------------
# Taps
# ---------------------------------------------------------------------------
tap "nikitabobko/tap"     # AeroSpace tiling window manager
tap "felixkratz/formulae" # SketchyBar custom menu bar

# ---------------------------------------------------------------------------
# CLI tools / formulae
# ---------------------------------------------------------------------------
brew "git"                    # newer git than the system one
brew "gh"                     # GitHub CLI
brew "stow"                   # symlink farm manager for the dotfiles
brew "starship"               # cross-shell prompt
brew "mise"                   # runtime version manager (node, python, ...)
brew "uv"                     # fast Python package/venv manager
brew "pipx"                   # install Python CLI apps in isolated envs

# Modern shell experience
brew "fzf"                    # fuzzy finder
brew "ripgrep"                # fast grep (rg)
brew "fd"                     # fast find
brew "bat"                    # cat with syntax highlighting
brew "eza"                    # modern ls
brew "zoxide"                 # smarter cd
brew "jq"                     # JSON processor (also used by SketchyBar plugins)
brew "wget"
brew "tree"
brew "btop"                   # resource monitor

# zsh plugins (sourced from .zshrc — no framework needed)
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
brew "zsh-completions"

# Window manager + menu bar
brew "sketchybar"             # the custom menu bar (config under dotfiles/sketchybar)

# ---------------------------------------------------------------------------
# Applications (casks)
# ---------------------------------------------------------------------------
# Terminal & editor
cask "iterm2"
cask "visual-studio-code"

# Window manager / menu bar
cask "nikitabobko/tap/aerospace"  # tiling WM (launches sketchybar on startup)
cask "rectangle"                  # simple window snapping (overlaps AeroSpace — see README)
cask "jordanbaird-ice"            # menu bar item manager (replaces unmaintained Dozer)

# Launchers / productivity
cask "raycast"
cask "alfred"                     # Alfred 5 (overlaps Raycast — see README)
cask "superwhisper"               # AI dictation
cask "claude"                     # Claude desktop app

# Communication
cask "slack"
cask "zoom"

# Browsers
cask "google-chrome"
cask "firefox"

# Security / accounts
cask "proton-pass"                # password manager (replaces Bitwarden)
cask "proton-mail"
cask "protonvpn"
cask "proton-drive"
cask "yubico-authenticator"

# ---------------------------------------------------------------------------
# Fonts
# ---------------------------------------------------------------------------
cask "font-hack-nerd-font"        # terminal / Starship / VS Code (Nerd glyphs)
cask "font-sketchybar-app-font"   # app glyphs in the SketchyBar
cask "font-sf-pro"                # SketchyBar bar font ("SF Pro")
cask "sf-symbols"                 # SF Symbols glyphs used by the bar
