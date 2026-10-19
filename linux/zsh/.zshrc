# Interactive Zsh configuration; machine-specific overrides belong in ~/.zshrc.local.
[[ -o interactive ]] || return
export EDITOR=nvim VISUAL=nvim
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
export BUN_INSTALL="${BUN_INSTALL:-$HOME/.bun}"
typeset -U path
path=("$HOME/.local/bin" "$HOME/bin" "$HOME/.cargo/bin" "$BUN_INSTALL/bin" $path)

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt AUTO_CD HIST_IGNORE_DUPS HIST_IGNORE_SPACE HIST_SAVE_NO_DUPS SHARE_HISTORY
setopt INTERACTIVE_COMMENTS

# Keep completion caches out of the repository and shared history private.
_dotfiles_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
mkdir -p -m 700 "$_dotfiles_cache"
[[ -e "$HISTFILE" ]] || (umask 077; : > "$HISTFILE")
autoload -Uz compinit
compinit -d "$_dotfiles_cache/zcompdump-$ZSH_VERSION"
zmodload zsh/complist
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
bindkey -e
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search
bindkey '^[[Z' reverse-menu-complete

alias ls='ls --color=auto'
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias gp='git push'
alias dcu='docker compose up'
alias dps='docker ps'
alias dcl='docker compose logs'
alias dcdd='docker compose down --rmi local -v --remove-orphans'
if ! (( $+commands[bat] )) && (( $+commands[batcat] )); then
  alias bat=batcat
fi

# Load the Zsh version of fzf bindings (Ubuntu's packaged fzf is also supported).
if (( $+commands[fzf] )); then
  if [[ -r /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
    source /usr/share/doc/fzf/examples/key-bindings.zsh
  elif [[ -r /usr/share/fzf/key-bindings.zsh ]]; then
    source /usr/share/fzf/key-bindings.zsh
  fi
fi
export FZF_DEFAULT_OPTS="${FZF_DEFAULT_OPTS:+$FZF_DEFAULT_OPTS }--layout=reverse --border=rounded --color=fg:252,bg:233,hl:180,fg+:254,bg+:235,hl+:180,info:109,prompt:108,pointer:180,marker:108"

# Resolve through this file's real path, so symlinks and repo relocation work.
DOTFILES_ROOT="${${(%):-%x}:A:h:h:h}"
if (( $+commands[tmux] && $+commands[fzf] )); then
  fzf_tmux_launcher() { "$DOTFILES_ROOT/linux/bin/tmux-sessionizer"; }
  _dotfiles_tmux_widget() { fzf_tmux_launcher; zle reset-prompt; }
  zle -N _dotfiles_tmux_widget
  bindkey '^T' _dotfiles_tmux_widget
fi
if (( $+commands[tmuxxer] )); then
  _dotfiles_tmuxxer_widget() { command tmuxxer; zle reset-prompt; }
  zle -N _dotfiles_tmuxxer_widget
  bindkey '^F' _dotfiles_tmuxxer_widget
fi

# These tools are optional: a fresh machine can start Zsh without them.
[[ -r "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
_dotfiles_conda="${CONDA_HOME:-$HOME/miniconda3}"
if [[ -r "$_dotfiles_conda/etc/profile.d/conda.sh" ]]; then
  source "$_dotfiles_conda/etc/profile.d/conda.sh"
fi
if [[ -n "${WSL_DISTRO_NAME:-}" && -S /mnt/wslg/PulseServer ]]; then
  export PULSE_SERVER=unix:/mnt/wslg/PulseServer
fi

# A usable prompt even when Powerlevel10k has not been installed yet.
PROMPT='%F{yellow}%~%f %(?.%F{green}.%F{red})>%f '
POWERLEVEL10K_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/powerlevel10k"
if [[ -r "$POWERLEVEL10K_DIR/powerlevel10k.zsh-theme" ]]; then
  source "$POWERLEVEL10K_DIR/powerlevel10k.zsh-theme"
  [[ -r "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"
fi

# Local configuration is intentionally not tracked. Plugins load after widgets.
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=244'
[[ -r /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# Syntax highlighting must be sourced last.
[[ -r /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
unset _dotfiles_cache _dotfiles_conda
true
