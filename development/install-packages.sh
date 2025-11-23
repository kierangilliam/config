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

# Install Python
curl -fsSL https://pyenv.run | bash
pyenv install 3.12
pyenv global 3.12
