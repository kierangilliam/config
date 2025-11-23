# Enables vi keybindings in Zsh line editor
bindkey -v

# Change cursor shape for different vi modes.
function zle-keymap-select {
    if [[ ${KEYMAP} == vicmd ]] ||
        [[ $1 = 'block' ]]; then
    echo -ne '\e[1 q'

    elif [[ ${KEYMAP} == main ]] ||
        [[ ${KEYMAP} == viins ]] ||
        [[ ${KEYMAP} = '' ]] ||
        [[ $1 = 'beam' ]]; then
    echo -ne '\e[5 q'
    fi
}
zle -N zle-keymap-select

# Use beam shape cursor on startup.
echo -ne '\e[5 q'

# Beam on start
echo -ne '\e[5 q'

_fix_cursor() {
   echo -ne '\e[5 q'
}

precmd_functions+=(_fix_cursor)

export KEYTIMEOUT=1
