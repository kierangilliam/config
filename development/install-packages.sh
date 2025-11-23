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

# Install pyenv
curl -fsSL https://pyenv.run | bash

# Initialize pyenv in current shell
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# Install Python 3.12 if not already installed
if ! pyenv versions --bare | grep -q "^3.12"; then
  pyenv install 3.12
fi
pyenv global 3.12
