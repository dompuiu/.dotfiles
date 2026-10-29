# Shared helpers for hunk zsh scripts. Source, don't execute.

herdr_bin="${HERDR_BIN_PATH:-herdr}"
hunk_root="${${(%):-%x}:A:h:h}"

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
# Usage: tuios_split_right <anchor_pane> <cwd> <--focus|--no-focus> <script>
tuios_split_right() {
  local anchor="$1" cwd="$2" focus="$3" script="$4" target id
  target="$(rightmost_pane "$anchor")"
  [[ -n "$target" ]] || target="$anchor"
  id="$("$herdr_bin" pane split --pane "$target" --direction right "$focus" 2>/dev/null \
    | jq -r '.result.pane.pane_id // empty' 2>/dev/null)"
  [[ -n "$id" ]] || return 1
  "$herdr_bin" pane rename "$id" hunk >/dev/null 2>&1
  "$herdr_bin" pane run "$id" "cd -- ${(q)cwd} && exec zsh ${(q)hunk_root}/scripts/${(q)script}" >/dev/null
}

focused_pane_id() {
  "$herdr_bin" pane list 2>/dev/null | jq -r \
    '[.result.panes[]? | select(.focused == true)][0].pane_id // empty' 2>/dev/null
}
