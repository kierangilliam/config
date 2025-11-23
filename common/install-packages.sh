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

pkg zsh tmux neovim fzf zoxide ripgrep

curl -sS https://starship.rs/install.sh | sh -s -- -y

# fd is called 'fd-find' on apt-based systems, but 'fd' on brew/pacman
if [ "$PM" = "apt" ]; then
  pkg fd-find
else
  pkg fd
fi
