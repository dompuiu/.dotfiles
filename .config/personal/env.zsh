addToPath() {
  if [[ "$PATH" != *"$1"* && -d "$1" ]]; then
    export PATH=$PATH:$1
  fi
}

addToPathFront() {
  if [[ "$PATH" != *"$1"* && -d "$1" ]]; then
    export PATH=$1:$PATH
  fi
}

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
