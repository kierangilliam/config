# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

if [[ -f "/opt/homebrew/bin/brew" ]] then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in Powerlevel10k
zinit ice depth=1; zinit light romkatv/powerlevel10k

# Load plugins
export NVM_LAZY_LOAD=true
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit light lukechilds/zsh-nvm

# Load completions
autoload -Uz compinit && compinit

zinit cdreplay -q

export CLAUDE_CODE_DISABLE_AUTO_MEMORY=1
if [[ "$CLAUDECODE" != "1" ]]; then
    eval "$(zoxide init --cmd cd zsh)"
fi

export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"

HISTFILE=~/.zsh_history
HISTSIZE=10000 # Sets how many commands zsh keeps in memory during the current session.
SAVEHIST=50000 # Sets how many commands are saved to the history file (HISTFILE).
setopt inc_append_history # Makes zsh append each command to the history file immediately when executed, instead of waiting until the shell exits.
HISTDUP=erase # Erases duplicates in history file
setopt appendhistory
setopt sharehistory # Shares history to all zsh shells at the same time
setopt hist_ignore_space # Makes it so that ` echo my_secret` wont get saved since there is a space before it
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Set up fzf key bindings and fuzzy completion
# https://github.com/junegunn/fzf?tab=readme-ov-file#setting-up-shell-integration
source <(fzf --zsh)
# https://github.com/junegunn/fzf/wiki/Configuring-shell-key-bindings
fzf-history-widget-accept() {
  fzf-history-widget
  zle accept-line
}
zle     -N   fzf-history-widget-accept
bindkey '^r' fzf-history-widget-accept
bindkey '^O' fzf-cd-widget
bindkey '^T' fzf-file-widget

export PATH="$HOME/.local/bin:$PATH"

## Styling
source ~/.p10k.zsh
# Disable sort when completing `git checkout`
zstyle ':completion:*:git-checkout:*' sort false
# Allow autocompletion to match lower and upper case `ls dow` will show `Downloads`
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
# Make ls show color
alias ls='ls --color'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Enables seeing dotfiles when doing something like `zed <TAB>`
setopt globdots

# Load extra profile-specific snippets if they exist
for f in "$HOME/.zshrc.d/"*.zsh; do
  [ -r "$f" ] && . "$f"
done
unset f

# Load machine-local overrides if present
[ -f "$HOME/.zshrc.local" ] && . "$HOME/.zshrc.local"
