export EDITOR=nvim
export VISUAL=nvim

alias ll="ls -lah"
alias gs="git status"
alias ga="git add ."
alias gc="git commit -m"
alias gp="git push"

# >>> tmuxxer >>>
if [[ $- == *i* ]]; then
_tmuxxer_sessionize() {
'/home/andrew/.cargo/bin/tmuxxer' sessionize
}
bind -x '"\C-f": "_tmuxxer_sessionize"'
fi
# <<< tmuxxer <<<

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
