#!/usr/bin/env zsh
# Runs INSIDE the herdr pane (has a TTY, cwd = invoking pane's project).
# Same as picker.zsh "Working tree (live)" path, without fzf: just become a
# live hunk watcher. Quitting hunk closes the pane.
setopt pipe_fail no_unset

theme_args=()
[[ -n "${HUNK_THEME:-}" ]] && theme_args=(--theme "$HUNK_THEME")

die() {
  print -r -- "$1"
  read -r '?press Enter to close'
  exit 1
}

(( $+commands[hunk] )) || die 'hunk not found on PATH (npm i -g hunkdiff)'

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not a git repository: $PWD"
repo_root="${repo_root:A}"

# Session-aware: if a hunk viewer is already open for this repo, reload it
# instead of stacking a second one; else become hunk.
if hunk session get --repo "$repo_root" >/dev/null 2>&1; then
  hunk session reload --repo "$repo_root" -- diff >/dev/null 2>&1 && exit 0
fi

exec hunk diff --watch "${theme_args[@]}"
