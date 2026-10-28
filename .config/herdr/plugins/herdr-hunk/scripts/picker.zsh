#!/usr/bin/env zsh
# Runs INSIDE the herdr pane (has a TTY, cwd = the invoking pane's project).
# fzf menu -> hunk viewer. Quitting hunk closes the pane.
setopt pipe_fail no_unset

theme_args=()
[[ -n "${HUNK_THEME:-}" ]] && theme_args=(--theme "$HUNK_THEME")

die() {
  print -r -- "$1"
  read -r '?press Enter to close'
  exit 1
}

(( $+commands[hunk] )) || die 'hunk not found on PATH (npm i -g hunkdiff)'
(( $+commands[fzf] )) || die 'fzf not found on PATH (brew install fzf)'
(( $+commands[git] )) || die 'git not found on PATH'

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not a git repository: $PWD"
repo_root="${repo_root:A}"

# Always open hunk in this pane: the launcher already closed any old hunk
# pane in this tab, and reloading a session elsewhere would be invisible.
hunk_view() {
  exec hunk "$@" "${theme_args[@]}"
}

first_word() {
  local line="${1//$'\e'\[[0-9;]#[A-Za-z]/}"
  print -r -- "${${(z)line}[1]:-}"
}

log_fzf() {
  git log --oneline --color=always -200 | fzf --ansi --no-sort --reverse --height=100% "$@" \
    --preview 'git show --stat --color=always {1}' --preview-window=right,55%
}

choice="$(print -l \
  'Working tree (live)' \
  'Staged' \
  'Last commit' \
  'Pick commit' \
  'Pick range (2 commits)' \
  'Branch vs upstream' \
  'Stash' | fzf --prompt='hunk> ' --reverse --height=100%)" || exit 0
[[ -n "$choice" ]] || exit 0

case "$choice" in
  'Working tree (live)')
    exec hunk diff --watch "${theme_args[@]}"
    ;;
  'Staged')
    hunk_view diff --staged
    ;;
  'Last commit')
    hunk_view show
    ;;
  'Pick commit')
    sel="$(log_fzf --prompt 'commit> ')" || exit 0
    sha="$(first_word "$sel")"
    [[ -n "$sha" ]] || exit 0
    hunk_view show "$sha"
    ;;
  'Pick range (2 commits)')
    picks="$(log_fzf --multi 2 --prompt='range> ' \
      --header='TAB marks a commit (pick 2). Enter confirms. 1 marked = diff vs working tree.')" || exit 0
    lines=("${(@f)picks}")
    lines=("${(@)lines:#}")
    if (( ${#lines} == 2 )); then
      # git log lists newest first; diff older..newer
      hunk_view diff "$(first_word "${lines[2]}")..$(first_word "${lines[1]}")"
    elif (( ${#lines} == 1 )); then
      hunk_view diff "$(first_word "${lines[1]}")"
    fi
    exit 0
    ;;
  'Branch vs upstream')
    branch="$(git branch --show-current 2>/dev/null)"
    [[ -n "$branch" ]] || branch=HEAD
    upstream="$(git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)" || upstream=''
    if [[ -z "$upstream" ]]; then
      for candidate in origin/main origin/master main master; do
        if git rev-parse --verify -q "$candidate" >/dev/null 2>&1; then
          upstream="$candidate"
          break
        fi
      done
    fi
    [[ -n "$upstream" ]] || die 'no upstream or base branch found'
    hunk_view diff "$upstream..$branch"
    ;;
  'Stash')
    sel="$(git stash list | fzf --prompt='stash> ' --reverse --height=100% --delimiter=: \
      --preview 'git stash show --stat --color=always {1}' --preview-window=right,55%)" || exit 0
    ref="${sel%%:*}"
    [[ -n "$ref" ]] || exit 0
    exec hunk stash show "$ref" "${theme_args[@]}"
    ;;
esac
