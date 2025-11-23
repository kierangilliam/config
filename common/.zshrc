eval "$(starship init zsh)"
eval "$(zoxide init zsh)"
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"

HISTFILE=~/.history
HISTSIZE=10000 # Sets how many commands zsh keeps in memory during the current session.
SAVEHIST=50000 # Sets how many commands are saved to the history file (HISTFILE).
setopt inc_append_history # Makes zsh append each command to the history file immediately when executed, instead of waiting until the shell exits.

# Set up fzf key bindings and fuzzy completion
# https://github.com/junegunn/fzf?tab=readme-ov-file#setting-up-shell-integration
source <(fzf --zsh)
# https://github.com/junegunn/fzf/wiki/Configuring-shell-key-bindings
fzf-history-widget-accept() {
  fzf-history-widget
  zle accept-line
}
zle     -N     fzf-history-widget-accept
bindkey '^r' fzf-history-widget-accept
bindkey '^O' fzf-cd-widget
bindkey '^T' fzf-file-widget

export PATH="$HOME/.local/bin:$PATH"

# Load extra profile-specific snippets if they exist
for f in "$HOME/.zshrc.d/"*.zsh; do
  [ -r "$f" ] && . "$f"
done
unset f

# Load machine-local overrides if present
[ -f "$HOME/.zshrc.local" ] && . "$HOME/.zshrc.local"
