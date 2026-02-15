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

pkg tmux neovim fzf zoxide ripgrep bat

# On Debian/Ubuntu, bat installs as batcat - create a symlink
if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
  mkdir -p ~/.local/bin
  ln -sf "$(which batcat)" ~/.local/bin/bat
fi
