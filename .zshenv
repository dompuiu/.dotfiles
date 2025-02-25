export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export ZSH_CACHE_DIR="$XDG_CACHE_HOME/ohmyzsh"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export HISTFILE="$ZDOTDIR/.zhistory" # History filepath.

export EDITOR="nvim"
export VISUAL="nvim"

export FZF_DEFAULT_COMMAND="fd --type file --follow --hidden --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/ripgreprc"
export PNPM_HOME="$XDG_DATA_HOME/pnpm"

export IGNOREEOF=1 # Emulate the Bash behavior of being able to specify the number of Ctrl+D sequences before exiting the shell.

[[ ! -f ~/.zshenv.local ]] || source ~/.zshenv.local
