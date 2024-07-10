# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

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
addPathToFront /snap/bin
addPathToFront $PNPM_HOME
addPathToFront /opt/homebrew/bin
addPathToFront /opt/homebrew/sbin
addPath $HOME/.cargo/bin

source "$HOME/.zi/bin/zi.zsh"
autoload -Uz _zi
(( ${+_comps} )) && _comps[zi]=_zi

zi snippet OMZL::clipboard.zsh
zi snippet OMZL::completion.zsh
zi snippet OMZL::key-bindings.zsh
zi snippet OMZL::history.zsh
zi snippet OMZL::functions.zsh
zi snippet OMZP::asdf/asdf.plugin.zsh
zi snippet OMZP::fzf/fzf.plugin.zsh
zi snippet OMZP::tmux/tmux.plugin.zsh

if [[ `uname` == "Darwin" ]]; then
  # zi ice svn; zi snippet OMZP::macos
fi

zi ice blockf; zi light zsh-users/zsh-completions
zi ice wait lucid atload'_zsh_autosuggest_start'; zi light zsh-users/zsh-autosuggestions
zi light z-shell/F-Sy-H # alternative to ---> zi light zsh-users/zsh-syntax-highlighting
zi light Aloxaf/fzf-tab
zi light wfxr/forgit
zi ice depth=1; zi light romkatv/powerlevel10k

# examples here -> https://wiki.zshell.dev/ecosystem/category/-annexes
zicompinit # <- https://wiki.zshell.dev/docs/guides/commands
zicdreplay -q

# Zoxide. The OPZP plugin doesn't let you provide flags to the init command.
checkIfCommandExists "zoxide" && eval "$(zoxide init zsh --cmd cd)"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
checkIfFileExists ~/.p10k.zsh || source ~/.p10k.zsh
checkIfFileExists ${HOME}/.iterm2_shell_integration.zsh || source "${HOME}/.iterm2_shell_integration.zsh"
checkIfCommandExists "cola" && alias mycola="(cola &> /dev/null &)"
! checkIfCommandExists "fd" && alias fd="fdfind"
alias v="fd --type f --hidden --exclude .git | fzf-tmux -p --reverse | xargs nvim"
alias ls='ls --color=auto'

# Bash like ctrl-d wrapper for IGNOREEOF
setopt ignore_eof
zle -N bash-ctrl-d
bindkey "^d" bash-ctrl-d

[[ ! -f ~/.zshrc.local ]] || source ~/.zshrc.local

