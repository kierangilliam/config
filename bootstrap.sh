#!/usr/bin/env bash

# Visual indicator to see where bootstrap gets called
# https://ascii.today/
cat <<'EOF'
 ________  ________  ________   ________ ___  ________
|\   ____\|\   __  \|\   ___  \|\  _____\\  \|\   ____\
\ \  \___|\ \  \|\  \ \  \\ \  \ \  \__/\ \  \ \  \___|
 \ \  \    \ \  \\\  \ \  \\ \  \ \   __\\ \  \ \  \  ___
  \ \  \____\ \  \\\  \ \  \\ \  \ \  \_| \ \  \ \  \|\  \
   \ \_______\ \_______\ \__\\ \__\ \__\   \ \__\ \_______\
    \|_______|\|_______|\|__| \|__|\|__|    \|__|\|_______|
EOF

set -euo pipefail

# Directory where this script lives (repo root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Gives us `pkg` which installs packages using this computer's correct package manager (brew/pacman/apt-get)
source "$SCRIPT_DIR/lib/package-helpers.sh"
pkg fzf stow

# ---------------------------
# Profile configuration
# ---------------------------

OPTIONAL_PROFILES=()
ALWAYS_ENABLED=("common")

# ---------------------------
# Helper functions
# ---------------------------

# Run install-packages.sh for a profile
# The profile script will source lib/package-helpers.sh for package installation
run_install_script() {
  local root="$1"
  local profile="$2"
  local install_script="$root/$profile/install-packages.sh"

  if [ ! -f "$install_script" ]; then
    echo "  (no install-packages.sh found, skipping)"
    return 0
  fi

  # Execute the install script (it will auto-detect the package manager)
  echo "  Running install-packages.sh..."
  "$install_script"
}

# ---------------------------
# Main
# ---------------------------

# Show info about always-enabled profiles
echo ""
echo "The following profiles are always enabled:"
for profile in "${ALWAYS_ENABLED[@]}"; do
  echo "  - $profile"
done
echo ""

# Use fzf for multi-select of optional profiles
selected_profiles=()
if [ ${#OPTIONAL_PROFILES[@]} -gt 0 ]; then
  echo "Select additional profiles to enable (use Tab to select/deselect, Enter to confirm):"
  # Convert array to newline-separated list for fzf
  mapfile -t selected_profiles < <(
    printf '%s\n' "${OPTIONAL_PROFILES[@]}" | \
    fzf --multi \
        --prompt="Select profiles: " \
        --header="Use Tab to select multiple, Enter to confirm" \
        --height=~40%
  ) || true  # Don't exit if user cancels (Ctrl-C returns non-zero)
fi

# Combine always-enabled + selected profiles
all_profiles=("${ALWAYS_ENABLED[@]}" "${selected_profiles[@]}")

echo ""
echo "Selected profiles:"
for profile in "${all_profiles[@]}"; do
  echo "  - $profile"
done
echo ""

# ----- Install packages -----

echo "Installing packages for each profile..."
for profile in "${all_profiles[@]}"; do
  echo "Profile: $profile"
  run_install_script "$SCRIPT_DIR" "$profile"
  echo ""
done

# ----- Stow dotfiles -----

echo "Stowing dotfiles..."
for profile in "${all_profiles[@]}"; do
  echo "  stow $profile"
  cd "$SCRIPT_DIR"
  stow -t "$HOME" "$profile"
done

echo ""
echo "Bootstrap complete!"
