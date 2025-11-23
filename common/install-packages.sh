#!/usr/bin/env bash
# install-packages.sh for common profile
# The PM environment variable contains the detected package manager (apt/brew/pacman)

set -euo pipefail

# Source the shared package helpers
source "$(dirname "$0")/../lib/package-helpers.sh"

# Core packages (same name across all package managers)
pkg zsh starship curl git stow tmux neovim fzf zoxide ripgrep

# fd is called 'fd-find' on apt-based systems, but 'fd' on brew/pacman
if [ "$PM" = "apt" ]; then
  pkg fd-find
else
  pkg fd
fi
