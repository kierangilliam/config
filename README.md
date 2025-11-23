# Config

Personal configuration files and package install scripts for various profiles (common, app-development, ssh-client).

## Install

TODO: Install sh command

## Profiles

- `common` Configuration and software I want across all machines
  - Aliases | Packages
- `app-development` Additional configuration and software I want when doing app development (e.g., Flutter)
  - Aliases | Packages
- `ssh-client` Additional configuration and software I want when SSH'ing into a remote server
  - Aliases | Packages

## How this works

- Package manager is detected (`brew`/`packman`/`apt-get`)
- Profile is selected (`common`/`app-development`/etc)
- Packages are installed for that profile
- Per-package configuration files (aka dotfiles) are installed using `stow`

## Testing locally

```
docker run --rm -it -v "$PWD":/workspace ubuntu:24.04 bash

# In the container
apt-get update
apt-get install -y curl
```
