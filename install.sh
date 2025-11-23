#!/usr/bin/env sh
set -eu

detect_pm() {
    if command -v apt-get >/dev/null 2>&1; then
        echo "apt"
    elif command -v brew >/dev/null 2>&1; then
        echo "brew"
    elif command -v pacman >/dev/null 2>&1; then
        echo "pacman"
    else
        echo "unsupported"
    fi
}

PM="$(detect_pm)"

if [ "$PM" = "unsupported" ]; then
    echo "No supported package manager (apt, brew, pacman)"
    exit 1
fi

case "$PM" in
    apt)
        sudo apt-get update
        sudo apt-get install -y git
        ;;
    brew)
        brew install git
        ;;
    pacman)
        sudo pacman -Syu --noconfirm git
        ;;
esac

TMPDIR="$(mktemp -d)"

git clone https://github.com/kierangilliam/config.git "$TMPDIR"

case "$PM" in
    apt)
        sudo apt-get install -y nushell
        ;;
    brew)
        brew install nushell
        ;;
    pacman)
        sudo pacman -S --noconfirm nushell
        ;;
esac

cd "$TMPDIR"
nu bootstrap.nu
