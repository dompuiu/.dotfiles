#!/usr/bin/env zsh
# Runs INSIDE the pane (has a TTY, cwd = invoking pane's project).
# Resolve tuicr (the pane inherits the herdr server's minimal PATH) and become
# it with any args passed (e.g. -w). Quitting tuicr closes the pane.
setopt pipe_fail no_unset

# For the repaired PATH (herdr panes inherit the server's minimal PATH):
# pick up Homebrew, cargo, ~/.local/bin and mise shims.
path=(/opt/homebrew/bin /usr/local/bin "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/.local/share/mise/shims" $path)

have_tuicr() {
  (( $+commands[tuicr] )) && tuicr --version >/dev/null 2>&1
}

die() {
  print -r -- "$1"
  read -r '?press Enter to close'
  exit 1
}

have_tuicr || die 'tuicr not found or broken (try: mise use -g github:agavra/tuicr@0.28.0, then restart herdr)'

exec tuicr "$@"
