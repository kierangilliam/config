---
name: my-omarchy
description: >
  My personal Omarchy machine + dotfiles conventions. Use for ANY question or
  change touching this OS, the desktop/window manager, or personal config: ~/personal_config,
  ~/.config/omarchy/, ~/.config/hypr/, ~/.zshrc and shell config, terminal config, themes,
  keybindings, packages, hardware/architecture questions. Triggers: "my OS", "my machine",
  "my dotfiles", "my config", omarchy, Omarchy Mac, Hyprland, personal_config, zshrc,
  aarch64. Load this BEFORE editing any of those files or answering OS questions.
---

# My Omarchy setup

## Machine
- Architecture: **aarch64** (assume arm64 packages/binaries; x86_64 instructions may not apply).
- Distro: **Omarchy Mac** — https://github.com/omarchy-mac/omarchy-mac — a fork that may
  differ slightly from mainline Omarchy.

## Dotfiles
- Personal dotfiles live in **`~/personal_config`** (git repo). Anything I want kept goes there.
- Most Omarchy dotfiles are *not* in `~/personal_config` — they come from the Omarchy default settings shipped with the distro.

### Editing an Omarchy setting that isn't backed up yet
1. First **snapshot the current (default) file** into `~/personal_config/omarchy/...`,
   mirroring its path.
2. Commit that snapshot alone with the message exactly: `default omarchy`
3. *Then* make the actual edit. Don't commit your edits unless I say to.

This keeps a clean before/after diff against stock Omarchy.

### Shell config
- Changes to `.zshrc` should usually go in the **omarchy-specific zshrc file** that is version
  controlled in `~/personal_config`, not in `~/.zshrc` directly.
- **Confirm with me** which file before editing shell config.

## Relationship to the built-in `omarchy` skill
The system-provided `omarchy` skill covers how Omarchy itself works. This skill layers my
personal conventions on top — when both apply, follow the built-in skill's mechanics and
this skill's conventions about *where files live and what gets committed*.
