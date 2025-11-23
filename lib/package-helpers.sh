#!/usr/bin/env bash
# lib/package-helpers.sh - Shared package management helpers
#
# Usage:
#   source "$(dirname "$0")/../lib/package-helpers.sh"
#   pkg zsh git curl
#   pkg neovim

# Track if apt-get update has been run
_apt_updated=false

# Helper function to install packages immediately
# Usage: pkg package1 [package2 ...]
# Requires PM environment variable to be set (apt/brew/pacman)
pkg() {
  if [ $# -eq 0 ]; then
    echo "Warning: pkg() called with no arguments" >&2
    return 0
  fi

  case "$PM" in
    apt)
      # Only run apt-get update once
      if [ "$_apt_updated" = false ]; then
        sudo apt-get update
        _apt_updated=true
      fi
      sudo apt-get install -y "$@"
      ;;
    brew)
      brew install "$@"
      ;;
    pacman)
      sudo pacman -S --noconfirm --needed "$@"
      ;;
    *)
      echo "Unsupported package manager: $PM" >&2
      return 1
      ;;
  esac
}
