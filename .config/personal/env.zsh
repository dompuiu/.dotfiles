checkIfCommandExists() {
  (( $+commands[$1] ))
}

checkIfFileExists() {
  [[ ! -f $1 ]]
}

bash-ctrl-d() {
  if [[ $CURSOR == 0 && -z $BUFFER ]]
  then
    [[ -z $IGNOREEOF || $IGNOREEOF == 0 ]] && exit
    if [[ "$LASTWIDGET" == "bash-ctrl-d" ]]
    then
      (( --__BASH_IGNORE_EOF <= 0 )) && exit
    else
      (( __BASH_IGNORE_EOF = IGNOREEOF ))
    fi
  fi
}

addPath() {
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
        PATH="${PATH:+"$PATH:"}$1"
    fi
}

addPathToFront() {
    [ -d "$1" ] || return
    PATH=":$PATH:"
    PATH="${PATH//:$1:/:}"   # strip existing occurrence
    PATH="${PATH#:}"; PATH="${PATH%:}"
    PATH="$1${PATH:+":$PATH"}"
}

# Resolve a command to the binary that actually runs, following mise shims so
# that tool upgrades are noticed. Sets REPLY to avoid a subshell.
realBinary() {
    local real
    REPLY=${commands[$1]}
    [[ -n $REPLY ]] || return 1
    if [[ ${REPLY:A} == */mise/shims/* ]]; then
        real=$(mise which "$1" 2>/dev/null | head -1)
        [[ -n $real ]] && REPLY=$real
    fi
    return 0
}

# Write a tool's completion to the zi completion dir, but only when the cache
# is missing or older than the binary.
cacheCompletion() {
    local name=$1; shift
    local file="$HOME/.zi/completions/_$name"
    local REPLY bin
    realBinary "$name" || return 1
    bin=$REPLY
    [[ -s $file && $file -nt $bin ]] && return 0
    mkdir -p "${file:h}"
    "$@" >| "$file"
    # Force the next compinit to rebuild its dump so the new file is picked up.
    command rm -f "${ZI[ZCOMPDUMP_PATH]:-$ZSH_CACHE_DIR/.zcompdump}"
}

# Source a tool's shell init script (`starship init zsh`, ...), regenerating
# the cached copy only when the binary is newer than the cache.
cacheInit() {
    local name=$1; shift
    local file="$XDG_CACHE_HOME/zsh/init-$name.zsh"
    local REPLY bin
    realBinary "$name" || return 1
    bin=$REPLY
    if [[ ! -s $file || $bin -nt $file ]]; then
        mkdir -p "${file:h}"
        "$@" >| "$file" || { command rm -f "$file"; return 1; }
    fi
    source "$file"
}

# compinit with its security audit (compaudit) skipped when the dump was
# rebuilt within the last 24 hours.
compinitCached() {
    autoload -Uz compinit
    local dump=${ZI[ZCOMPDUMP_PATH]}
    local -a fresh=($dump(N.mh-24))
    if (( $#fresh )); then
        compinit -C -d "$dump"
    else
        compinit -d "$dump"
        command touch "$dump"
    fi
}
