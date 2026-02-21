#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib/package-helpers.sh"

cat <<'EOF'
   ____ ___  __  __ __  __  ___  _   _
  / ___/ _ \|  \/  |  \/  |/ _ \| \ | |
 | |  | | | | |\/| | |\/| | | | |  \| |
 | |__| |_| | |  | | |  | | |_| | |\  |
  \____\___/|_|  |_|_|  |_|\___/|_| \_|
EOF

# On macOS (brew), skip zsh (it's pre-installed)
if [ "$PM" != "brew" ]; then
  pkg zsh
fi

pkg tmux neovim zoxide ripgrep bat

# Install fzf from git to get latest version (apt version is too old for --zsh flag)
if [ ! -d "$HOME/.fzf" ]; then
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  "$HOME/.fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
fi

# On Debian/Ubuntu, bat installs as batcat - create a symlink
if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
  mkdir -p ~/.local/bin
  ln -sf "$(which batcat)" ~/.local/bin/bat
fi
