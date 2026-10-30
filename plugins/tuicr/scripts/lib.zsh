# Shared helpers for tuicr zsh scripts. Source, don't execute.

herdr_bin="${HERDR_BIN_PATH:-herdr}"
plugin_root="${${(%):-%x}:A:h:h}"

# tuios runs herdr plugins through a herdr-compatible CLI of its own.
in_tuios() { [[ -n "${TUIOS_PLUGIN_ID:-}${TUIOS_SOCKET:-}" || "$herdr_bin" == *tuios* ]]; }

# Pane with the rightmost edge in the tab of pane $1 (tallest on ties).
rightmost_pane() {
  "$herdr_bin" pane layout --pane "$1" 2>/dev/null | jq -r '
    [.result.layout.panes[]? | select(.rect != null)]
    | sort_by(.rect.x + .rect.width, .rect.height) | last | .pane_id // empty' 2>/dev/null
}

# tuios ignores --direction on `plugin pane open`, and on `pane split` as soon
# as --cwd or --env is passed. So split plain, label the pane like herdr does,
# then cd and exec the pane script in its shell.
# Usage: tuios_split_right <anchor_pane> <cwd> <--focus|--no-focus> <script> [args...]
tuios_split_right() {
  local anchor="$1" cwd="$2" focus="$3" script="$4" target id
  shift 4
  target="$(rightmost_pane "$anchor")"
  [[ -n "$target" ]] || target="$anchor"
  id="$("$herdr_bin" pane split --pane "$target" --direction right "$focus" 2>/dev/null \
    | jq -r '.result.pane.pane_id // empty' 2>/dev/null)"
  [[ -n "$id" ]] || return 1
  "$herdr_bin" pane rename "$id" tuicr >/dev/null 2>&1
  "$herdr_bin" pane run "$id" "builtin cd -- ${(q)cwd} && exec zsh ${(q)plugin_root}/scripts/${(q)script} ${(q@)@}" >/dev/null
}

focused_pane_id() {
  "$herdr_bin" pane list 2>/dev/null | jq -r \
    '[.result.panes[]? | select(.focused == true)][0].pane_id // empty' 2>/dev/null
}

# Root panes at the invoking pane's directory, not the plugin install dir.
# Context JSON is injected by herdr on action invoke; fall back to the focused
# pane's cwd, then HOME.
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
