#!/usr/bin/env zsh
# Action launcher (runs detached, no TTY): open the picker pane in the
# invoking pane's project. Usage: open-hunk-picker.zsh [split|tab]
setopt pipe_fail no_unset

source "${0:A:h}/lib.zsh"
placement="${1:-split}"

(( $+commands[jq] )) || { "$herdr_bin" notification show 'hunk: jq not found on PATH' --position top-right; exit 1; }

# Root the picker at the invoking pane's directory, not the plugin install
# dir. Context JSON is injected by herdr on action invoke; fall back to the
# focused pane's cwd, then HOME.
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

cwd="$(target_cwd)"

# Re-pressing the key in split mode: close any existing hunk pane in the
# focused tab so the picker starts fresh instead of stacking splits.
if [[ "$placement" == split ]]; then
  "$herdr_bin" pane list 2>/dev/null | jq -r '
    (.result.panes // []) as $panes
    | ($panes | map(select(.focused == true)) | first) as $f
    | if $f == null then empty
      else $panes[] | select(.label == "hunk" and .tab_id == $f.tab_id) | .pane_id // empty
      end' 2>/dev/null | while read -r old_id; do
    [[ -n "$old_id" ]] && "$herdr_bin" pane close "$old_id" >/dev/null 2>&1
  done
fi

if [[ "$placement" == split ]] && in_tuios; then
  anchor="$(focused_pane_id)"
  [[ -n "$anchor" ]] && tuios_split_right "$anchor" "$cwd" --focus picker.zsh && exit 0
fi

open_args=(plugin pane open
  --plugin hunk --entrypoint hunk-picker
  --placement "$placement" --focus
  --cwd "$cwd")
[[ "$placement" == split ]] && open_args+=(--direction right)

open_out="$("$herdr_bin" "${open_args[@]}" 2>/dev/null)"
open_exit=$?
[[ -n "$open_out" ]] && print -r -- "$open_out"
(( open_exit == 0 )) || exit $open_exit

# --focus updates server focus but does not navigate attached clients.
# Explicit `tab focus` does, so pull the new tab id from the open response.
[[ "$placement" == tab ]] || exit 0
tab_id="$(print -r -- "$open_out" | jq -r '
  (.result.plugin_pane // .result) as $p
  | $p.pane.tab_id // $p.tab_id // .result.tab.tab_id // empty' 2>/dev/null)"
if [[ -z "$tab_id" ]]; then
  pane_id="$(print -r -- "$open_out" | jq -r '
    (.result.plugin_pane // .result) as $p | $p.pane.pane_id // $p.pane_id // empty' 2>/dev/null)"
  [[ -n "$pane_id" ]] && tab_id="$("$herdr_bin" pane get "$pane_id" 2>/dev/null | jq -r '.result.pane.tab_id // empty' 2>/dev/null)"
fi
[[ -n "$tab_id" ]] || exit 0
"$herdr_bin" tab focus "$tab_id" >/dev/null
