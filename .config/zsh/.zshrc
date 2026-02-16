if [[ ! -f $HOME/.zi/bin/zi.zsh ]]; then
  print -P "%F{33}▓▒░ %F{160}Installing (%F{33}z-shell/zi%F{160})…%f"
  command mkdir -p "$HOME/.zi" && command chmod go-rwX "$HOME/.zi"
  command git clone -q --depth=1 --branch "main" https://github.com/z-shell/zi "$HOME/.zi/bin" && \
    print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
    print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

PERSONAL=$XDG_CONFIG_HOME/personal
source $PERSONAL/env.zsh

if type brew &>/dev/null
then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

addPathToFront $HOME/.local/bin
addPathToFront $HOME/.local/share/bob/nvim-bin
addPathToFront $PNPM_HOME
addPathToFront /opt/homebrew/bin
addPathToFront /opt/homebrew/sbin
addPath $HOME/.cargo/bin
addPath /usr/local/cuda/bin

source "$HOME/.zi/bin/zi.zsh"
autoload -Uz _zi
(( ${+_comps} )) && _comps[zi]=_zi

zi snippet OMZL::clipboard.zsh
zi snippet OMZL::completion.zsh
zi snippet OMZL::key-bindings.zsh
zi snippet OMZL::history.zsh
zi snippet OMZL::functions.zsh
zi snippet OMZP::mise/mise.plugin.zsh
zi snippet OMZP::fzf/fzf.plugin.zsh

zi ice blockf; zi light zsh-users/zsh-completions
zi ice wait lucid atload'_zsh_autosuggest_start'; zi light zsh-users/zsh-autosuggestions
zi light z-shell/F-Sy-H # alternative to ---> zi light zsh-users/zsh-syntax-highlighting
zi light Aloxaf/fzf-tab
zi light wfxr/forgit

checkIfCommandExists "zellij" && zellij setup --generate-completion zsh > ~/.zi/completions/_zellij

# examples here -> https://wiki.zshell.dev/ecosystem/category/-annexes
if [[ -d "$HOME/.zi/completions" ]]; then
  command find "$HOME/.zi/completions" -xtype l -delete 2>/dev/null
fi
zicompinit # <- https://wiki.zshell.dev/docs/guides/commands
zicdreplay -q

# Zoxide. The OPZP plugin doesn't let you provide flags to the init command.
checkIfCommandExists "zoxide" && eval "$(zoxide init zsh --cmd cd)"

checkIfFileExists ${HOME}/.iterm2_shell_integration.zsh || source "${HOME}/.iterm2_shell_integration.zsh"

! checkIfCommandExists "fd" && checkIfCommandExists "fdfind" && alias fd="fdfind"
alias realfind="/usr/bin/find"
checkIfCommandExists "fd" && alias find="fd"

alias realcat="/bin/cat"
checkIfCommandExists "bat" && alias cat="bat --paging=never"

alias realls='/bin/ls --color=auto'
checkIfCommandExists "eza" && alias ls="eza"

# Bash like ctrl-d wrapper for IGNOREEOF
setopt ignore_eof
zle -N bash-ctrl-d
bindkey "^d" bash-ctrl-d

# Init starship
eval "$(starship init zsh)"

[[ ! -f ~/.zshrc.local ]] || source ~/.zshrc.local
