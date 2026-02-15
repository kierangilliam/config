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
pkg stow

# ---------------------------
# Profile configuration
# ---------------------------

OPTIONAL_PROFILES=("development", "remove_development")
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

selected_profiles=()
if [ ${#OPTIONAL_PROFILES[@]} -gt 0 ]; then
  echo "Select additional profiles to enable:"
  for profile in "${OPTIONAL_PROFILES[@]}"; do
    read -p "  Enable '$profile'? (y/N): " response
    case "$response" in
      [yY]|[yY][eE][sS])
        selected_profiles+=("$profile")
        ;;
      *)
        # Default to no for any other input
        ;;
    esac
  done
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
cd "$SCRIPT_DIR"
echo "  stow ${all_profiles[*]}"
stow -t "$HOME" --ignore='install-packages.sh' "${all_profiles[@]}"

echo ""
echo "Bootstrap complete!"
