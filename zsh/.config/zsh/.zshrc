# ============================================================================
# ZSH Configuration
# ============================================================================

# ── Shell Initialization ──────────────────────────────────────────────────
eval "$(zoxide init zsh)"
eval "$(starship init zsh)"

# ── Environment Variables ─────────────────────────────────────────────────
export EDITOR=nvim

# lazygit looks in ~/Library/Application Support on macOS by default; point it
# at the stow-managed config in ~/.config instead
export LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml"

export JAVA_HOME=$(/usr/libexec/java_home -v17)
export PATH=$JAVA_HOME/bin:$PATH

# Windsurf
export PATH="/Users/rituraj/.codeium/windsurf/bin:$PATH"

# LM Studio CLI
export PATH="$PATH:/Users/rituraj/.lmstudio/bin"

# Emacs
export PATH="$PATH:~/.config/emacs/bin"

# Local binaries
. "$HOME/.local/bin/env"

# ── NVM (Node Version Manager) ────────────────────────────────────────────
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ── Aliases ───────────────────────────────────────────────────────────────
alias ls="eza --icons=always"
alias vim="nvim"
alias cat="bat"
alias python="python3"
alias n="nvim"
alias v="nvim"
alias cdsp="claude --dangerously-skip-permissions"

# ── Shell Options ─────────────────────────────────────────────────────────
setopt autocd                 # Change directories without explicitly typing cd
setopt extendedglob           # Enables extended globbing features
setopt nomatch                # Prevents error when glob doesn't match any files
setopt menucomplete           # Tab complete, cycle through possible completions
setopt interactive_comments   # Allows comments in interactive ZSH session

# Disable paste highlighting
zle_highlight=('paste:none')

# ── VIM Mode ──────────────────────────────────────────────────────────────
bindkey -v

# ── Keybindings ───────────────────────────────────────────────────────────
bindkey -s '^t' 'tmux-sessionizer\n'

# ── Completion System ─────────────────────────────────────────────────────
autoload -Uz compinit && compinit

# Case-insensitive tab completion
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'

# ── Functions ─────────────────────────────────────────────────────────────

# Tmux session manager - opens tmux with folder name as session name
tm() {
  local session
  session="$(basename "$PWD")"

  # Check if session exists using list-sessions
  if tmux list-sessions -F "#{session_name}" 2>/dev/null | grep -q "^${session}$"; then
    echo "Attaching to existing session: $session"
    tmux attach -t "$session"
  else
    echo "Creating new session: $session"
    tmux new-session -s "$session"
  fi
}

# ── External Completions ──────────────────────────────────────────────────

# tabtab source for electron-forge package
# uninstall by removing these lines or running `tabtab uninstall electron-forge`
[[ -f /Users/rituraj/.npm/_npx/6913fdfd1ea7a741/node_modules/tabtab/.completions/electron-forge.zsh ]] && . /Users/rituraj/.npm/_npx/6913fdfd1ea7a741/node_modules/tabtab/.completions/electron-forge.zsh
