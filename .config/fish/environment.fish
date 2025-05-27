set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_CACHE_HOME $HOME/.cache

set -gx EDITOR nvim
set -gx VISUAL nvim

set -gx FZF_DEFAULT_COMMAND "fd --type file --follow --hidden --exclude .git"
set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
set -gx RIPGREP_CONFIG_PATH $XDG_CONFIG_HOME/ripgrep/ripgreprc
set -gx PNPM_HOME $XDG_DATA_HOME/pnpm
