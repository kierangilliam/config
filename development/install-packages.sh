#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib/package-helpers.sh"

# Install Python
pkg pyenv
pyenv install 3.12
pyenv global 3.12
