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

pkg zsh tmux neovim fzf zoxide ripgrep bat

if ! command -v starship &>/dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi
