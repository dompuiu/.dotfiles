#!/usr/bin/env zsh
# Runs INSIDE the pane (has a TTY, cwd = invoking pane's project).
# Become tuicr with any args passed (e.g. -w). Quitting tuicr closes the pane.
setopt pipe_fail no_unset

die() {
  print -r -- "$1"
  read -r '?press Enter to close'
  exit 1
}

# For the repaired PATH (herdr panes inherit the server's minimal PATH).
source "${0:A:h}/lib.zsh"

have_tuicr || die 'tuicr not found or broken (try: mise use -g github:agavra/tuicr@0.28.0, then restart herdr)'

exec tuicr "$@"
