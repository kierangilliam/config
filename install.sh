#!/usr/bin/env sh
set -eu

TMPDIR="$(mktemp -d)"
git clone https://github.com/kierangilliam/config.git "$TMPDIR"

cd "$TMPDIR"
sh bootstrap.sh
