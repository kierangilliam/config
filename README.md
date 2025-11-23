# Config

Personal configuration files and package install scripts for various profiles (common, development).

## Install

Prerequisites: `git`, `curl`

```
apt-get update
apt-get install -y curl git
```

Install packages and dotfiles:

```
curl https://raw.githubusercontent.com/kierangilliam/config/refs/heads/main/install.sh | sh
```

## Profiles

- `common` Configuration and software I want across all machines
- `development` Additional configuration and software for programming development, like Python

## How this works

- Package manager is detected (`brew`/`packman`/`apt-get`)
- Profile is selected (`common`/`app-development`/etc)
- Packages are installed for that profile
- Per-package configuration files (aka dotfiles) are installed using `stow`

## Tools

- `zsh`: Configured with [starship](https://starship.rs/config/).
- `ripgrep`: [Guide](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md). A better `grep`. Usage: `rg`.
- `tmux`
- `bat`: A better `cat`. Usage: `bat`.
- `zoxide`: A better `cd`. Usage: `z`.
- `fd`: A better `find`. Usage: `fd`.
- `fzf`: Fuzzy finding tool
  - `fzf --preview="bat --color=always {}"`: Search directories with fzf
  - `Ctrl+t` list files+folders in current directory (e.g., type git add , press Ctrl+t, select a few files using Tab, finally Enter)
  - `Ctrl+r` search history of shell commands
  - `Ctrl+o` fuzzy change directory

## Testing locally

```
docker run --rm -it -v "$PWD":/workspace ubuntu:24.04 bash
```

In the container:

```
cd /workspace && \
  apt-get update && \
  apt-get install -y curl git && \
  bash bootstrap.sh
```

The following commands should work:

```
zsh
```
