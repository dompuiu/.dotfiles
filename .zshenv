# Bootstrap: zsh reads this file before ZDOTDIR is known. Nested shells inherit
# ZDOTDIR and read $ZDOTDIR/.zshenv directly, so the real config lives there.
export ZDOTDIR="$HOME/.config/zsh"
source "$ZDOTDIR/.zshenv"
