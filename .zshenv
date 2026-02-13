export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export ZSH_CACHE_DIR="$XDG_CACHE_HOME/ohmyzsh"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"
export HISTFILE="$ZDOTDIR/.zhistory" # History filepath.

export EDITOR="nvim"
export VISUAL="nvim"

if whence -p fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND="fd --type file --follow --hidden --exclude .git"
elif whence -p fdfind >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND="fdfind --type file --follow --hidden --exclude .git"
else
  unset FZF_DEFAULT_COMMAND
fi
if [[ -n ${FZF_DEFAULT_COMMAND} ]]; then
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
else
  unset FZF_CTRL_T_COMMAND
fi
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/ripgreprc"
export PNPM_HOME="$XDG_DATA_HOME/pnpm"

export IGNOREEOF=1 # Emulate the Bash behavior of being able to specify the number of Ctrl+D sequences before exiting the shell.

[[ ! -f ~/.zshenv.local ]] || source ~/.zshenv.local
