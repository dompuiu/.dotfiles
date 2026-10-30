#!/usr/bin/env zsh
# Runs INSIDE the pane (has a TTY, cwd = invoking pane's project).
# Become tuicr with any args passed (e.g. -w). Quitting tuicr closes the pane.
setopt pipe_fail no_unset

die() {
  print -r -- "$1"
  read -r '?press Enter to close'
  exit 1
}

(( $+commands[tuicr] )) || die 'tuicr not found on PATH (brew install tuicr)'

exec tuicr "$@"
