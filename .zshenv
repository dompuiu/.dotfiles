export XDG_CONFIG_HOME="$HOME/.config"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export HISTFILE="$ZDOTDIR/.zhistory"    # History filepath

export EDITOR="nvim"
export VISUAL="nvim"

export FZF_DEFAULT_COMMAND="fd --type file --follow --hidden --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

PERSONAL=$XDG_CONFIG_HOME/personal
source $PERSONAL/env.zsh

addToPath "$HOME/.local/bin"
addToPath "/snap/bin"
