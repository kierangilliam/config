#!/usr/bin/env bash
# bootstrap.sh - Dotfiles installation script

set -euo pipefail

# ---------------------------
# Profile configuration
# ---------------------------

OPTIONAL_PROFILES=("laptop" "ssh-client")
ALWAYS_ENABLED=("common")

# ---------------------------
# Helper functions
# ---------------------------

detect_pm() {
  if command -v apt-get &>/dev/null; then
    echo "apt"
  elif command -v brew &>/dev/null; then
    echo "brew"
  elif command -v pacman &>/dev/null; then
    echo "pacman"
  else
    echo "Unsupported OS / package manager" >&2
    exit 1
  fi
}

# Run install-packages.sh for a profile
# The profile script will source lib/package-helpers.sh for package installation
run_install_script() {
  local root="$1"
  local profile="$2"
  local pm="$3"
  local install_script="$root/$profile/install-packages.sh"

  if [ ! -f "$install_script" ]; then
    echo "  (no install-packages.sh found, skipping)"
    return 0
  fi

  # Execute the install script with PM variable set
  # The script will handle the actual installation
  echo "  Running install-packages.sh..."
  PM="$pm" bash "$install_script"
}

# ---------------------------
# Main
# ---------------------------

# Directory where this script lives (repo root)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Show info about always-enabled profiles
echo ""
echo "The following profiles are always enabled:"
for profile in "${ALWAYS_ENABLED[@]}"; do
  echo "  - $profile"
done
echo ""

# Use fzf for multi-select if available, otherwise skip optional profiles
selected_profiles=()
if command -v fzf &>/dev/null && [ ${#OPTIONAL_PROFILES[@]} -gt 0 ]; then
  echo "Select additional profiles to enable (use Tab to select/deselect, Enter to confirm):"
  # Convert array to newline-separated list for fzf
  mapfile -t selected_profiles < <(
    printf '%s\n' "${OPTIONAL_PROFILES[@]}" | \
    fzf --multi \
        --prompt="Select profiles: " \
        --header="Use Tab to select multiple, Enter to confirm" \
        --height=~40%
  ) || true  # Don't exit if user cancels (Ctrl-C returns non-zero)
elif [ ${#OPTIONAL_PROFILES[@]} -gt 0 ]; then
  echo "Note: fzf not found. Skipping optional profile selection."
  echo "To enable profile selection, fzf will be installed with the 'common' profile."
  echo "You can re-run this script after installation to select optional profiles."
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

PM=$(detect_pm)
echo "Detected package manager: $PM"
echo ""

echo "Installing packages for each profile..."
for profile in "${all_profiles[@]}"; do
  echo "Profile: $profile"
  run_install_script "$SCRIPT_DIR" "$profile" "$PM"
  echo ""
done

# ----- Stow dotfiles -----

echo "Stowing dotfiles..."
for profile in "${all_profiles[@]}"; do
  echo "  stow $profile"
  cd "$SCRIPT_DIR"
  stow "$profile"
done

echo ""
echo "Bootstrap complete!"
