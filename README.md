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
git clone https://github.com/kierangilliam/config ~/personal_config
cd ~/personal_config
bash bootstrap.sh
```

## Profiles

- `common` Configuration and software I want across all machines
- `development` Additional configuration and software for programming development, like Python

## How this works

- Package manager is detected (`brew`/`packman`/`apt-get`)
- Profile is selected (`common`/`development`/etc)
- Packages are installed for that profile
- Per-package configuration files (aka dotfiles) are installed using `stow`

## Tools

- `zsh`: Configured with [p10k](https://github.com/romkatv/powerlevel10k) prompt.
- `ripgrep`: [Guide](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md). A better `grep`. Usage: `rg`.
- `tmux`
- `bat`: A better `cat`. Usage: `bat`.
- `zoxide`: A better `cd`. Usage: `z`. Replaces `cd`.
- `fzf`: Fuzzy finding tool
  - `fzf --preview="bat --color=always {}"`: Search directories with fzf
  - `Ctrl+t` list files+folders in current directory (e.g., type git add , press Ctrl+t, select a few files using Tab, finally Enter)
  - `Ctrl+r` search history of shell commands
  - `Ctrl+o` fuzzy change directory

### Development

- `lazygit`
- `lazydocker`

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

## Resources

- [Youtube: ZSH Config](https://youtu.be/ud7YxC33Z3w?si=f3GbejZf58TwBYUc)
