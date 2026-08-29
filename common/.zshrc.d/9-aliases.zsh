alias zshsanitycheck="echo ZSH was set up properly"

alias zshconfig="vim ~/.zshrc"
alias restart='source ~/.zshrc'

alias nr='npm run '
alias ni='npm install '

alias vim="nvim"
alias vi="nvim"
alias v="nvim"

alias gp="git push"

alias grep='grep --color=auto'

alias ..=' cd ..; ls'
alias ...=' cd ..; cd ..; ls'
alias ....=' cd ..; cd ..; cd ..; ls'

alias dc='docker compose'
alias dcu='docker compose up'
alias dcd='docker compose down'
alias dcr='docker compose run'
alias dcb='docker compose build'

alias cgit='cd ~/Documents/git'

# Docker Sandboxes: HERDR_AGENT lets herdr detect claude behind the sbx wrapper
alias sbxc='HERDR_AGENT=claude sbx run claude'
