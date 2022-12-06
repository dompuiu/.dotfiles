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
