if [[ ! -f $HOME/.zi/bin/zi.zsh ]]; then
  print -P "%F{33}▓▒░ %F{160}Installing (%F{33}z-shell/zi%F{160})…%f"
  command mkdir -p "$HOME/.zi" && command chmod go-rwX "$HOME/.zi"
  command git clone -q --depth=1 --branch "main" https://github.com/z-shell/zi "$HOME/.zi/bin" && \
    print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
    print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

PERSONAL=$XDG_CONFIG_HOME/personal
source $PERSONAL/env.zsh

# Homebrew's zsh completions. Checking known prefixes avoids running
# `brew --prefix` (or scanning a long PATH for a missing `brew`) every shell.
for brew_prefix in "${HOMEBREW_PREFIX:-}" /opt/homebrew /home/linuxbrew/.linuxbrew /usr/local; do
  [[ -n $brew_prefix && -d $brew_prefix/share/zsh/site-functions ]] || continue
  FPATH="$brew_prefix/share/zsh/site-functions:${FPATH}"
  break
done
unset brew_prefix

addPathToFront $HOME/.local/share/bob/nvim-bin
addPathToFront $PNPM_HOME/bin
addPathToFront $HOME/.local/bin
addPathToFront /home/linuxbrew/.linuxbrew/bin
addPathToFront /home/linuxbrew/.linuxbrew/sbin
addPathToFront /opt/homebrew/bin
addPathToFront /opt/homebrew/sbin
addPathToFront $HOME/.cargo/bin
addPath /usr/local/cuda/bin

source "$HOME/.zi/bin/zi.zsh"
autoload -Uz _zi
(( ${+_comps} )) && _comps[zi]=_zi

zi snippet OMZL::clipboard.zsh
zi snippet OMZL::completion.zsh
zi snippet OMZL::key-bindings.zsh
zi snippet OMZL::history.zsh
zi snippet OMZL::functions.zsh
# Shims mode: tool versions still resolve through mise's shims, but the shell
# skips the per-prompt hook that costs ~300 ms at startup.
command -v mise >/dev/null 2>&1 && eval "$(mise activate zsh --shims)"
cacheCompletion mise mise completion zsh
zi ice wait lucid; zi snippet OMZP::fzf/fzf.plugin.zsh

zi ice blockf; zi light zsh-users/zsh-completions
zi ice wait lucid atload'_zsh_autosuggest_start'; zi light zsh-users/zsh-autosuggestions
zi light z-shell/F-Sy-H # alternative to ---> zi light zsh-users/zsh-syntax-highlighting
zi light MichaelAquilina/zsh-autoswitch-virtualenv
zi light Aloxaf/fzf-tab
zi light wfxr/forgit

cacheCompletion tuios tuios completion zsh
cacheCompletion herdr herdr completion zsh

# examples here -> https://wiki.zshell.dev/ecosystem/category/-annexes
if [[ -d "$HOME/.zi/completions" ]]; then
  for link in "$HOME/.zi/completions"/*(N@); do
    [[ -e "$link" ]] || command rm -f "$link"
  done
fi
zicompinit # <- https://wiki.zshell.dev/docs/guides/commands
zicdreplay -q

# Zoxide. The OPZP plugin doesn't let you provide flags to the init command.
checkIfCommandExists "zoxide" && eval "$(zoxide init zsh --cmd cd)"

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

# Record how long this shell took to load. It stays silent unless asked:
# `ZSH_STARTUP_TIME=1 zsh` prints it, `zsh-startup` measures a fresh shell.
if [[ -n $ZSH_STARTUP_START ]]; then
  typeset -gi ZSH_STARTUP_MS=$(( (EPOCHREALTIME - ZSH_STARTUP_START) * 1000 ))
  unset ZSH_STARTUP_START
  if [[ ${ZSH_STARTUP_TIME:-0} != 0 ]]; then
    print -P "%F{244}zsh startup: ${ZSH_STARTUP_MS} ms%f"
  fi
fi

zsh-startup() {
  ZSH_STARTUP_TIME=1 zsh -i -c exit
}
