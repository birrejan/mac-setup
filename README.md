# mac-setup

One-command provisioning for a fresh Mac. Clone the repo, run `./install.sh`, and end up with a
fully configured development machine: Homebrew packages, GUI apps, language runtimes, dotfiles,
a tiling window manager with a custom menu bar, sensible macOS defaults, SSH keys, and signed commits.

Built around **Homebrew + a Brewfile**, **GNU Stow** for dotfiles, and a set of small, **idempotent**
scripts (safe to re-run). Apple Silicon and Intel both supported.

---

## Quick start

```bash
# 1. Install the Xcode Command Line Tools (a GUI dialog will pop up).
#    install.sh also triggers this automatically if missing.
xcode-select --install

# 2. Clone the repo (HTTPS works before your SSH key exists).
git clone https://github.com/<your-username>/mac-setup.git ~/mac-setup
cd ~/mac-setup

# 3. Run it.
./install.sh
```

Useful flags:

```bash
./install.sh --yes          # assume "yes" for every confirmation
./install.sh --skip-macos   # everything except the macOS system tweaks
./install.sh --only ssh     # run a single step (see list below)
```

Steps (run in this order, each also runnable via `--only <name>`):
`preflight` → `homebrew` → `dotfiles` → `languages` → `git` → `ssh` → `vscode` → `wm` → `macos`.

---

## What gets installed

### CLI / shell
| Tool | Purpose |
|------|---------|
| `git`, `gh` | Git + GitHub CLI |
| `stow` | symlinks the dotfiles into `$HOME` |
| `starship` | shell prompt |
| `mise` | runtime version manager (Node, Python) |
| `uv`, `pipx` | Python package / app managers |
| `fzf`, `ripgrep`, `fd`, `bat`, `eza`, `zoxide`, `jq`, `btop` | modern CLI workflow |
| `zsh-autosuggestions`, `zsh-syntax-highlighting`, `zsh-completions` | zsh plugins (no framework) |
| `sketchybar` | the custom menu bar |

### Languages (via `mise`)
**Node.js (LTS)** + **Python 3.13**, declared in `dotfiles/mise/.config/mise/config.toml`.
`corepack` is enabled for `pnpm`/`yarn`. Add more anytime: `mise use -g go@latest`.

### Applications
| Category | Apps |
|----------|------|
| Terminal / editor | iTerm2, VS Code |
| Window manager / menu bar | **AeroSpace** (tiling), **SketchyBar** (menu bar), Rectangle, Ice |
| Launchers / AI | Raycast, Alfred 5, Superwhisper, Claude |
| Comms | Slack, Zoom |
| Browsers | Google Chrome, Firefox |
| Security / accounts | Proton Pass, Proton Mail, Proton VPN, Proton Drive, Yubico Authenticator |
| Fonts | Hack Nerd Font, SketchyBar app font, SF Pro, SF Symbols |

### Dotfiles (symlinked by Stow)
`~/.zshrc`, `~/.zshenv`, `~/.gitconfig`, `~/.gitignore_global`, `~/.config/starship.toml`,
`~/.config/mise/config.toml`, `~/.config/aerospace/aerospace.toml`, `~/.config/sketchybar/*`.

### macOS defaults (`scripts/macos.sh`)
Fast key repeat, no press-and-hold, tap-to-click, dark mode, Finder (show extensions / path bar /
hidden files / list view), screenshots → `~/Screenshots` as PNG, Dock (small, autohide, no recents,
stable Spaces). Every block is commented with how to revert.

---

## Window manager + menu bar (AeroSpace + SketchyBar)

These configs were captured from a working machine and are reproduced **verbatim**.

- **AeroSpace** is a tiling window manager. It starts at login, launches SketchyBar, and notifies it
  on workspace changes. Config: `~/.config/aerospace/aerospace.toml`.
- **SketchyBar** is the custom top bar (workspaces, front app, media, clock, battery, CPU, volume).
  It runs as a Homebrew service. Config: `~/.config/sketchybar/`.

### Key AeroSpace bindings (all use `alt`)
| Keys | Action |
|------|--------|
| `alt + h/j/k/l` | focus left/down/up/right |
| `alt + shift + h/j/k/l` | move window |
| `alt + 1…0` | switch to workspace 1–10 |
| `alt + shift + 1…0` | move window to workspace and follow |
| `alt + f` | fullscreen |
| `alt + shift + space` | toggle floating / tiling |
| `alt + slash` / `alt + comma` | tiles / accordion layout |
| `alt + r` | resize mode (then `h/j/k/l`, `enter`/`esc` to exit) |
| `alt + shift + c` | reload AeroSpace config |
| `alt + tab` | previous workspace |

> The `aerospace.toml` `[workspace-to-monitor-force-assignment]` block references
> `"Built-in Retina Display"` — harmless on a single-display Mac; edit it for your monitor layout.

---

## Customization

- **Add/remove apps & tools** → edit `Brewfile`, then `brew bundle --file=Brewfile`.
- **Enable extra tooling** (Docker/OrbStack, kubectl, Terraform, cloud CLIs, Go, watchman, mysql,
  nmap, tmux, …) → uncomment lines in `Brewfile.optional`, then `brew bundle --file=Brewfile.optional`.
- **VS Code extensions** → edit `vscode/extensions.txt`, re-run `./install.sh --only vscode`.
- **Prompt** → edit `dotfiles/starship/.config/starship.toml` (live).
- **Shell** → edit `dotfiles/zsh/.zshrc`; machine-specific bits go in `~/.zshrc.local` (untracked).

### How the dotfiles work
Each subdirectory of `dotfiles/` is a **Stow package** whose internal tree mirrors `$HOME`.
`stow` symlinks the files into place, so editing a file in the repo edits the live config.

Add a new dotfile:
```bash
# e.g. add ~/.config/ghostty/config
mkdir -p dotfiles/ghostty/.config/ghostty
mv ~/.config/ghostty/config dotfiles/ghostty/.config/ghostty/config
stow --dir=dotfiles --target="$HOME" ghostty   # (and add it to PACKAGES in scripts/dotfiles.sh)
```

---

## Git identity & signed commits

`scripts/git.sh` prompts once for your name + email and writes them to `~/.gitconfig.local`
(**never committed**). The tracked `~/.gitconfig` includes that file and configures **SSH-based
commit signing**.

`scripts/ssh.sh` generates an `ed25519` key, loads it into the agent + macOS Keychain, and prints
the public key. **Add it to GitHub as both an Authentication key and a Signing key** so your commits
show as **Verified**:

```bash
gh auth login
gh ssh-key add ~/.ssh/id_ed25519.pub --type authentication
gh ssh-key add ~/.ssh/id_ed25519.pub --type signing
```

---

## Manual follow-ups (printed at the end of `install.sh`)

1. Restart the terminal (`exec zsh`) to load the new config.
2. Add the SSH key to GitHub (authentication + signing).
3. **Grant Accessibility permissions** (System Settings → Privacy & Security → Accessibility):
   AeroSpace, Rectangle, Raycast, Alfred. *(Cannot be scripted — macOS security.)*
4. iTerm2 → set font to **Hack Nerd Font Mono**, import a color preset.
5. Sign in to apps: Proton, Slack, Claude, Alfred, Superwhisper, Yubico.
6. Confirm SketchyBar is running: `brew services list | grep sketchybar`.

---

## Notes / overlaps

- **AeroSpace + Rectangle** and **Alfred 5 + Raycast** are both installed by request, but overlap
  (tiling vs snapping; two launchers). Drop either by removing its `cask` line from the `Brewfile`.
- No Mac App Store apps (avoids interactive sign-in). Add `mas` + `mas "App", id: …` if you want them.
- iTerm2 preferences are a manual step; full automation can be added later via `PrefsCustomFolder`.

---

## Repo layout

```
mac-setup/
├── install.sh              # orchestrator
├── Brewfile                # everything installed by default
├── Brewfile.optional       # opt-in tooling (commented)
├── scripts/                # one idempotent script per concern
│   ├── lib.sh  preflight.sh  homebrew.sh  dotfiles.sh  languages.sh
│   └── git.sh  ssh.sh  vscode.sh  wm.sh  macos.sh
├── dotfiles/               # Stow packages (zsh, git, starship, mise, aerospace, sketchybar)
└── vscode/                 # settings.json, keybindings.json, extensions.txt
```

---

## Verification

```bash
bash -n install.sh scripts/*.sh            # syntax
brew bundle check --file=Brewfile          # all installed?
stow -n -d dotfiles -t ~ zsh git starship mise aerospace sketchybar   # dry-run symlinks
mise current && node -v && python -V        # runtimes
git config --get commit.gpgsign             # → true
brew services list | grep sketchybar        # → started
```
