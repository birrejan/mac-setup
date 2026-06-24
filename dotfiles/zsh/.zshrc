# ~/.zshrc — managed by mac-setup (symlinked from the repo via GNU Stow).
# Machine-local tweaks go in ~/.zshrc.local (sourced at the end, not tracked).

# --- Homebrew (arch-aware: Apple Silicon /opt/homebrew, Intel /usr/local) ---
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x /usr/local/bin/brew ]]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi
export BREW_PREFIX="${HOMEBREW_PREFIX:-$(brew --prefix 2>/dev/null)}"

# --- PATH ------------------------------------------------------------------
export PATH="$HOME/.local/bin:$PATH"   # pipx / uv tools

# --- Editor / locale -------------------------------------------------------
export EDITOR="code --wait"
export VISUAL="$EDITOR"
export LANG="en_US.UTF-8"

# --- Completions (must precede compinit) -----------------------------------
if [[ -n "$BREW_PREFIX" ]]; then
  fpath=("$BREW_PREFIX/share/zsh-completions" "$BREW_PREFIX/share/zsh/site-functions" $fpath)
fi
autoload -Uz compinit
compinit -C
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive

# --- History ---------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS INC_APPEND_HISTORY
setopt AUTO_CD INTERACTIVE_COMMENTS

# --- Plugins (installed via Homebrew) --------------------------------------
[[ -r "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] \
  && source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

# --- Tool initialisation ---------------------------------------------------
command -v starship >/dev/null && eval "$(starship init zsh)"   # prompt
command -v mise     >/dev/null && eval "$(mise activate zsh)"   # runtimes (node/python)
command -v zoxide   >/dev/null && eval "$(zoxide init zsh)"     # smarter cd → `z`
if command -v fzf >/dev/null; then
  source <(fzf --zsh) 2>/dev/null \
    || [[ -r "$BREW_PREFIX/opt/fzf/shell/key-bindings.zsh" ]] && source "$BREW_PREFIX/opt/fzf/shell/key-bindings.zsh"
fi

# --- Aliases ---------------------------------------------------------------
if command -v eza >/dev/null; then
  alias ls='eza --group-directories-first'
  alias ll='eza -lah --group-directories-first --git'
  alias la='eza -a'
  alias lt='eza --tree --level=2'
else
  alias ll='ls -lah'
fi
command -v bat >/dev/null && alias cat='bat --paging=never'
alias g='git'
alias gs='git status -sb'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'
alias gco='git checkout'
alias gp='git push'
alias gpl='git pull'
alias ..='cd ..'
alias ...='cd ../..'
alias reload='exec zsh'

# --- Syntax highlighting (MUST be sourced last) ----------------------------
[[ -r "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] \
  && source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# --- Machine-local overrides (not tracked) ---------------------------------
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
