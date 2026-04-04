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

pkg tmux neovim ripgrep bat

# Install zoxide - brew version is fine, apt version is too old (missing builtin cd fix)
if [ "$PM" = "brew" ]; then
  pkg zoxide
else
  ZOXIDE_VERSION="0.9.9"
  if ! command -v zoxide &>/dev/null || [[ "$(zoxide --version)" != "zoxide $ZOXIDE_VERSION" ]]; then
    ARCH="$(uname -m)"
    case "$ARCH" in
      x86_64)  ZOXIDE_ARCH="x86_64-unknown-linux-musl" ;;
      aarch64) ZOXIDE_ARCH="aarch64-unknown-linux-musl" ;;
      *)       echo "Unsupported architecture: $ARCH" >&2; exit 1 ;;
    esac
    mkdir -p ~/.local/bin
    curl -sSfL "https://github.com/ajeetdsouza/zoxide/releases/download/v${ZOXIDE_VERSION}/zoxide-${ZOXIDE_VERSION}-${ZOXIDE_ARCH}.tar.gz" \
      | tar -xz -C ~/.local/bin zoxide
  fi
fi

# Install fzf from git to get latest version (apt version is too old for --zsh flag)
if [ ! -d "$HOME/.fzf" ]; then
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  "$HOME/.fzf/install" --key-bindings --completion --no-update-rc --no-bash --no-fish
fi

# On Debian/Ubuntu, bat installs as batcat - create a symlink
if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
  mkdir -p ~/.local/bin
  ln -sf "$(which batcat)" ~/.local/bin/bat
fi
