#!/usr/bin/env zsh
# Toggle a live hunk diff in a split pane: OPEN if absent in the focused tab,
# FOCUS if present but unfocused, CLOSE if it is the focused pane.
setopt pipe_fail no_unset

source "${0:A:h}/lib.zsh"

(( $+commands[jq] )) || { "$herdr_bin" notification show 'hunk: jq not found on PATH' --position top-right; exit 1; }

target_cwd() {
  local cwd
  cwd="$(print -r -- "${HERDR_PLUGIN_CONTEXT_JSON:-}" | jq -r \
    '.focused_pane_cwd // .workspace_cwd // .cwd // empty' 2>/dev/null)"
  if [[ ! -d "$cwd" ]]; then
    cwd="$("$herdr_bin" pane list 2>/dev/null | jq -r \
      '[.result.panes[]? | select(.focused == true)][0].cwd // empty' 2>/dev/null)"
  fi
  [[ -d "$cwd" ]] || cwd="$HOME"
  print -r -- "$cwd"
}

open_pane() {
  local anchor cwd
  if in_tuios; then
    anchor="$(focused_pane_id)"
    cwd="$(target_cwd)"
    [[ -n "$anchor" ]] && tuios_split_right "$anchor" "$cwd" --focus hunk-diff.zsh && exit 0
  fi
  exec "$herdr_bin" plugin pane open \
    --plugin hunk --entrypoint hunk-diff \
    --placement split --direction right --focus \
    --cwd "$(target_cwd)"
}

panes="$("$herdr_bin" pane list 2>/dev/null)" || open_pane
[[ -n "$panes" ]] || open_pane

# Decide OPEN / "FOCUS <id>" / "CLOSE <id>". Only a hunk pane in the focused
# pane's tab counts.
decision="$(print -r -- "$panes" | jq -r '
  (.result.panes // []) as $panes
  | ($panes | map(select(.focused == true)) | first) as $focused
  | if $focused == null then "OPEN"
    else
      ($panes | map(select(.label == "hunk" and .tab_id == $focused.tab_id)) | first) as $h
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
