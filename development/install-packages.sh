#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib/package-helpers.sh"

cat <<'EOF'
____  _______     _______ _     ___  ____  __  __ _____ _   _ _____
|  _ \| ____\ \   / / ____| |   / _ \|  _ \|  \/  | ____| \ | |_   _|
| | | |  _|  \ \ / /|  _| | |  | | | | |_) | |\/| |  _| |  \| | | |
| |_| | |___  \ V / | |___| |__| |_| |  __/| |  | | |___| |\  | | |
|____/|_____|  \_/  |_____|_____\___/|_|   |_|  |_|_____|_| \_| |_|
EOF

# lazygit and lazydocker aren't in standard apt repos (until Ubuntu 25.10+)
if [ "$PM" = "apt" ]; then
  # lazygit - https://github.com/jesseduffield/lazygit#debian-and-ubuntu
  if ! command -v lazygit &>/dev/null; then
    LAZYGIT_VERSION=$(curl -fs "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": *"v\K[^"]*')
    curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf /tmp/lazygit.tar.gz -C /tmp lazygit
    sudo install /tmp/lazygit -D -t /usr/local/bin/
    rm /tmp/lazygit /tmp/lazygit.tar.gz
  fi
  # lazydocker - https://github.com/jesseduffield/lazydocker#binary-release-linuxmacos
  if ! command -v lazydocker &>/dev/null; then
    curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
  fi
elif [ "$PM" = "brew" ]; then
  pkg lazygit lazydocker
elif [ "$PM" = "pacman" ]; then
  pkg lazygit lazydocker
fi

# Install Python build dependencies
# Based on: https://github.com/pyenv/pyenv/wiki#suggested-build-environment
if [ "$PM" = "apt" ]; then
  pkg make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev \
      libsqlite3-dev curl git libncursesw5-dev xz-utils tk-dev \
      libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
elif [ "$PM" = "brew" ]; then
  pkg openssl readline sqlite3 xz tcl-tk@8 libb2 zstd zlib pkgconfig
elif [ "$PM" = "pacman" ]; then
  pkg base-devel openssl zlib xz tk zstd
fi

# Only install pyenv and python if neither are found
if ! command -v pyenv &>/dev/null && ! command -v python3 &>/dev/null; then
  echo "Neither pyenv nor python found, installing..."

  # Install pyenv
  curl -fsSL https://pyenv.run | bash

  # Initialize pyenv in current shell
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$PATH"
  eval "$(pyenv init -)"

  # Install Python 3.12
  pyenv install 3.12
  pyenv global 3.12
else
  echo "Python or pyenv already installed, skipping installation"
fi
