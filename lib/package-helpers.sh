#!/usr/bin/env bash
# lib/package-helpers.sh - Shared package management helpers
#
# Usage:
#   source "$(dirname "$0")/../lib/package-helpers.sh"
#   pkg zsh git curl
#   pkg neovim

# Detect package manager
if command -v apt-get &>/dev/null; then
  PM="apt"
elif command -v brew &>/dev/null; then
  PM="brew"
  # On macOS, check if we're running under Rosetta 2 on an ARM Mac
  if [ "$(uname -s)" = "Darwin" ]; then
    # Check if we're running under Rosetta 2
    if [ "$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)" = "1" ]; then
      # Running under Rosetta 2, force brew to run under arm64
      BREW_CMD="arch -arm64 brew"
    else
      BREW_CMD="brew"
    fi
  else
    BREW_CMD="brew"
  fi
elif command -v pacman &>/dev/null; then
  PM="pacman"
else
  echo "Error: Unsupported package manager" >&2
  echo "Supported: apt-get, brew, pacman" >&2
  exit 1
fi

# Track if apt-get update has been run
_apt_updated=false

# Helper function to install packages immediately
# Usage: pkg package1 [package2 ...]
pkg() {
  if [ $# -eq 0 ]; then
    echo "Warning: pkg() called with no arguments" >&2
    return 0
  fi

  case "$PM" in
    apt)
      # Only run apt-get update once
      if [ "$_apt_updated" = false ]; then
        apt-get update
        _apt_updated=true
      fi
      DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
      ;;
    brew)
      $BREW_CMD install "$@"
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
