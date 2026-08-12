export EDITOR=nvim
export VISUAL=nvim

# Keep user-installed commands available without assuming a specific username.
path=("$HOME/.local/bin" "$HOME/.cargo/bin" $path)

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt AUTO_CD
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY

autoload -Uz compinit && compinit

alias ll="ls -lah"
alias gs="git status"
alias ga="git add ."
alias gc="git commit -m"
alias gp="git push"

if command -v tmuxxer >/dev/null 2>&1; then
  tmuxxer-sessionize() {
    tmuxxer sessionize
  }
  zle -N tmuxxer-sessionize
  bindkey '^F' tmuxxer-sessionize
fi

export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

POWERLEVEL10K_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/powerlevel10k"
if [[ -r "$POWERLEVEL10K_DIR/powerlevel10k.zsh-theme" ]]; then
  source "$POWERLEVEL10K_DIR/powerlevel10k.zsh-theme"
fi

[[ -r "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"
