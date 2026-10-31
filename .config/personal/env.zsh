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

# Write a tool's completion to the zi completion dir, but only when the cache
# is missing or older than the binary. Tools resolved through a mise shim are
# compared against the real binary, so upgrades invalidate the cache.
cacheCompletion() {
    local name=$1; shift
    local file="$HOME/.zi/completions/_$name"
    local bin real
    bin=$(command -v "$name" 2>/dev/null) || return 1
    if [[ ${bin:A} == */mise/shims/* ]]; then
        real=$(mise which "$name" 2>/dev/null | head -1)
        [[ -n $real ]] && bin=$real
    fi
    [[ -s $file && $file -nt $bin ]] && return 0
    mkdir -p "${file:h}"
    "$@" >| "$file"
}
