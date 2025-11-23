#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib/package-helpers.sh"

# Install Python
curl -fsSL https://pyenv.run | bash
pyenv install 3.12
pyenv global 3.12
