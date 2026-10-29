#!/usr/bin/env zsh
# Action: focus the most recently used open workspace other than the current one.
source "${0:A:h}/lib.zsh"
need jq

# tuios never fires workspace.focused, so track.zsh keeps no history there.
# Use the sessions' last_active instead.
if in_tuios; then
  sessions="$(tuios ls --json 2>/dev/null)" || { toast 'tuios ls failed'; exit 1; }
  current="$(jq -r '[.[] | select(.attached == true and (.saved // false | not))]
    | sort_by(-.last_active) | first.name // empty' <<< "$sessions")"
  target="$(jq -r --arg cur "$current" '[.[] | select(.name != $cur and (.saved // false | not))]
    | sort_by(-.last_active) | first.name // empty' <<< "$sessions")"
  [[ -n "$target" ]] || { toast 'no previous session'; exit 0; }
  args=("$target")
  [[ -n "$current" ]] && args+=(-s "$current")
  tuios switch-session "${args[@]}" >/dev/null
  exit $?
fi

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
