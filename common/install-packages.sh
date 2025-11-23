#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib/package-helpers.sh"

pkg zsh tmux neovim fzf zoxide ripgrep

curl -sS https://starship.rs/install.sh | sh -s -- -y

# fd is called 'fd-find' on apt-based systems, but 'fd' on brew/pacman
if [ "$PM" = "apt" ]; then
  pkg fd-find
else
  pkg fd
fi
