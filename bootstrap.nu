#!/usr/bin/env nu
# bootstrap.nu

# ---------------------------
# Profile configuration
# ---------------------------
# packages are read from <stow>/_packages
let profiles = [
  {
    key: common
    label: "common"
    selectable: false   # always on
    stow: "common"
  }
  {
    key: laptop
    label: "laptop"
    selectable: true
    stow: "laptop"
  }
  {
    key: ssh-client
    label: "ssh-client"
    selectable: true
    stow: "ssh-client"
  }
]

# ---------------------------
# Helper functions
# ---------------------------

def detect-pm [] -> string {
  if (which apt-get | is-empty) == false {
    "apt"
  } else if (which brew | is-empty) == false {
    "brew"
  } else if (which pacman | is-empty) == false {
    "pacman"
  } else {
    print "Unsupported OS / package manager"
    exit 1
  }
}

def install-apt [pkgs: list<string>] {
  sudo apt-get update
  sudo apt-get install -y ...$pkgs
}

def install-brew [pkgs: list<string>] {
  brew update
  brew install ...$pkgs
}

def install-pacman [pkgs: list<string>] {
  sudo pacman -Syu --noconfirm ...$pkgs
}

# Load pkgs from <root>/<stow>/_packages (if present)
def load-profile [root p] {
  let pkg_file = ($root | path join $p.stow "_packages")

  let pkgs = if (ls $pkg_file | is-empty) {
    []
  } else {
    open --raw $pkg_file
      | lines
      | each {|l| $l | str trim}
      | where {|l| $l != "" and (not ($l | str starts-with "#"))}
  }

  $p | upsert pkgs $pkgs
}

# ---------------------------
# Main
# ---------------------------

# Directory where this script lives (assumed to be repo root)
let root = ($env.FILE_PWD? | default (pwd))

# Attach pkgs to each profile by reading <stow>/_packages
let profiles_loaded = ($profiles | each {|p| load-profile $root $p })

# ----- Selection UI -----

let selectable_profiles = (
  $profiles_loaded
  | enumerate
  | where {|it| $it.item.selectable }
)

print ""
print "Select extra profiles to enable (comma separated):"
$selectable_profiles | each {|p|
  print $"  ($p.index + 1)) ($p.item.label)"
}
print ""
print "The following profiles are always enabled:"
($profiles_loaded | where {|p| $p.selectable == false } | each {|p|
  print $"  - ($p.label)"
})
print ""

let choice = (input "Your selection (e.g. '1,2' or profile names; empty for none): ")

let tokens = (
  $choice
  | split row ","
  | each {|x| $x | str trim | str downcase}
  | where {|x| $x != ""}
)

let selected_optional = (
  $selectable_profiles
  | where {|p|
      $tokens | any {|t|
        let idx_str = (($p.index + 1) | into string)
        let label_lc = ($p.item.label | str downcase)
        let key_lc   = ($p.item.key | into string | str downcase)
        $t == $idx_str or $t == $label_lc or $t == $key_lc
      }
    }
  | get item
)

let always_on = ($profiles_loaded | where {|p| $p.selectable == false })

let all_selected = ($always_on | append $selected_optional)

# ----- Build final package list -----

let pkgs_unique = (
  $all_selected
  | get pkgs
  | flatten
  | sort
  | uniq
)

# ----- Install packages -----

let pm = (detect-pm)

match $pm {
  "apt" => { install-apt $pkgs_unique }
  "brew" => { install-brew $pkgs_unique }
  "pacman" => { install-pacman $pkgs_unique }
  _ => {
    print $"Unexpected package manager: ($pm)"
    exit 1
  }
}

# ----- Stow dotfiles -----

$all_selected | each {|p|
  stow $p.stow
}
