checkIfCommandExists() {
  [[ -x "$(command -v $1)" ]]
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
    if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
      PATH="$1${PATH:+":$PATH"}"
    fi
}
