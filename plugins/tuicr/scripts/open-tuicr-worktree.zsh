#!/usr/bin/env zsh
# Toggle a tuicr review of uncommitted changes in a split pane: OPEN if absent in the focused tab,
# FOCUS if present but unfocused, CLOSE if it is the focused pane.
setopt pipe_fail no_unset

source "${0:A:h}/lib.zsh"

(( $+commands[jq] )) || { "$herdr_bin" notification show 'tuicr: jq not found on PATH' --position top-right; exit 1; }

open_pane() {
  local anchor cwd
  if in_tuios; then
    anchor="$(focused_pane_id)"
    cwd="$(target_cwd)"
    [[ -n "$anchor" ]] && tuios_split_right "$anchor" "$cwd" --focus tuicr.zsh -w && exit 0
  fi
  exec "$herdr_bin" plugin pane open \
    --plugin tuicr --entrypoint tuicr-worktree \
    --placement split --direction right --focus \
    --cwd "$(target_cwd)"
}

panes="$("$herdr_bin" pane list 2>/dev/null)" || open_pane
[[ -n "$panes" ]] || open_pane

# Decide OPEN / "FOCUS <id>" / "CLOSE <id>". Only a tuicr pane in the focused
# pane's tab counts.
decision="$(print -r -- "$panes" | jq -r '
  (.result.panes // []) as $panes
  | ($panes | map(select(.focused == true)) | first) as $focused
  | if $focused == null then "OPEN"
    else
      ($panes | map(select(.label == "tuicr" and .tab_id == $focused.tab_id)) | first) as $h
      | if $h == null or (($h.pane_id // "") == "") then "OPEN"
        elif $h.pane_id == $focused.pane_id then "CLOSE \($h.pane_id)"
        else "FOCUS \($h.pane_id)"
        end
    end' 2>/dev/null)" || decision=OPEN

case "$decision" in
  "CLOSE "*)
    exec "$herdr_bin" pane close "${decision#CLOSE }"
    ;;
  "FOCUS "*)
    pane_id="${decision#FOCUS }"
    # Plugin panes: prefer explicit focus, fall back to the zoom trick.
    "$herdr_bin" plugin pane focus "$pane_id" 2>/dev/null && exit 0
    "$herdr_bin" pane zoom "$pane_id" --on >/dev/null 2>&1
    exec "$herdr_bin" pane zoom "$pane_id" --off
    ;;
  *)
    open_pane
    ;;
esac
