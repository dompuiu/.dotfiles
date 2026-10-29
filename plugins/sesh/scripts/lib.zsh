# Shared helpers for sesh zsh scripts. Source, don't execute.
setopt pipe_fail no_unset extended_glob

# herdr runs hooks/actions with a minimal PATH.
path=(/opt/homebrew/bin /usr/local/bin "$HOME/.local/bin" "$HOME/.cargo/bin" $path)

herdr_bin="${HERDR_BIN_PATH:-herdr}"
plugin_id="${HERDR_PLUGIN_ID:-sesh}"

# tuios runs herdr plugins through a herdr-compatible CLI of its own.
in_tuios() { [[ -n "${TUIOS_PLUGIN_ID:-}${TUIOS_SOCKET:-}" || "$herdr_bin" == *tuios* ]]; }

toast() { "$herdr_bin" notification show "sesh: $1" --position top-right >/dev/null 2>&1; }

need() {
  local cmd
  for cmd in "$@"; do
    (( $+commands[$cmd] )) || { toast "$cmd not found on PATH"; print -u2 -r -- "missing: $cmd"; exit 1; }
  done
}

state_dir() {
  local dir="${HERDR_PLUGIN_STATE_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/sesh}"
  mkdir -p "$dir"
  print -r -- "$dir"
}

config_dir() {
  local dir="${HERDR_PLUGIN_CONFIG_DIR:-}"
  [[ -n "$dir" ]] || dir="$("$herdr_bin" plugin config-dir "$plugin_id" 2>/dev/null | tail -n 1)"
  print -r -- "$dir"
}

# One history file per herdr session; workspace ids are per-server.
history_file() { print -r -- "$(state_dir)/history-${HERDR_SESSION:-default}"; }

# Prints "id<TAB>label<TAB>focused<TAB>cwd<TAB>agent_status<TAB>linked" per open workspace.
list_workspaces() {
  local ws panes
  ws="$("$herdr_bin" workspace list 2>/dev/null)" || return 1
  panes="$("$herdr_bin" pane list 2>/dev/null)" || panes='{}'
  jq -r --argjson panes "$panes" '
    ($panes.result.panes // []) as $p
    | .result.workspaces[]?
    | . as $w
    | (([$p[] | select(.workspace_id == $w.workspace_id) | .cwd] | first)
        // $w.worktree.checkout_path
        // "") as $cwd
    | [$w.workspace_id, ($w.label // ""), ($w.focused | tostring), $cwd,
       ($w.agent_status // ""), (($w.worktree.is_linked_worktree // false) | tostring),
       ($w.worktree.repo_root // "")] | @tsv' <<< "$ws"
}

focus_workspace() { "$herdr_bin" workspace focus "$1" >/dev/null; }

expand_path() {
  local p="${1/#\~/$HOME}"
  print -r -- "${(e)p}"
}
