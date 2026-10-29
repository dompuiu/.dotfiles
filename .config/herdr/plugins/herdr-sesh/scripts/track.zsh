#!/usr/bin/env zsh
# Event hook (workspace.focused / workspace.closed): keep an MRU list of
# workspace ids, most recent first.
source "${0:A:h}/lib.zsh"
need jq

evt="${HERDR_PLUGIN_EVENT_JSON:-}"
[[ -n "$evt" ]] || exit 0
kind="$(jq -r '.data.type // .event // empty' <<< "$evt")"
ws_id="$(jq -r '.data.workspace_id // .workspace_id // empty' <<< "$evt")"
[[ -n "$ws_id" ]] || exit 0

hist="$(history_file)"
typeset -a ids
[[ -r "$hist" ]] && ids=("${(@f)$(<"$hist")}")
ids=("${(@)ids:#$ws_id}")
[[ "$kind" == *closed* ]] || ids=("$ws_id" "${ids[@]}")

tmp="$hist.$$"
print -rl -- "${(@)ids[1,50]}" > "$tmp" && mv -f "$tmp" "$hist"
