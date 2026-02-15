#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/../lib/package-helpers.sh"

cat <<'EOF'
_____ _____ _____ _____ _____ _____    ____  _____ _____
| __  |   __|     |     |_   _|   __|  |    \|   __|  |  |
|    -|   __| | | |  |  | | | |   __|  |  |  |   __|  |  |
|__|__|_____|_|_|_|_____| |_| |_____|  |____/|_____|\___/
EOF

pkg tmux
