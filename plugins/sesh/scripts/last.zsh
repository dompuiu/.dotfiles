#!/usr/bin/env zsh
# Action: focus the most recently used open workspace other than the current one.
source "${0:A:h}/lib.zsh"
need jq

typeset -A open
current=''
while IFS=$'\t' read -r id label focused cwd _rest; do
  [[ -n "$id" ]] || continue
  open[$id]=1
  [[ "$focused" == true ]] && current="$id"
done < <(list_workspaces)

hist="$(history_file)"
if [[ -r "$hist" ]]; then
  while read -r id; do
    [[ -n "$id" && "$id" != "$current" && -n "${open[$id]+x}" ]] || continue
    focus_workspace "$id"
    exit $?
  done < "$hist"
fi

toast 'no previous workspace'
