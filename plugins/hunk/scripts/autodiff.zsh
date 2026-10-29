#!/usr/bin/env zsh
# Event hook for pane.agent_status_changed: when an agent goes idle with
# uncommitted changes, open a live hunk diff split beside its pane (unfocused).
# Opt out: touch "$(herdr plugin config-dir hunk)/autodiff-off"
setopt pipe_fail no_unset

# Skip reasons go to stdout -> visible via `herdr plugin log`.
skip() { print -r -- "skip: $1"; exit 0; }

source "${0:A:h}/lib.zsh"

# herdr runs hooks with a minimal PATH.
path=(/opt/homebrew/bin /usr/local/bin "$HOME/.local/bin" $path)

cfg_dir="${HERDR_PLUGIN_CONFIG_DIR:-}"
[[ -n "$cfg_dir" ]] || cfg_dir="$("$herdr_bin" plugin config-dir hunk 2>/dev/null | tail -n 1)"
[[ -n "$cfg_dir" && -e "$cfg_dir/autodiff-off" ]] && skip 'autodiff off'

(( $+commands[jq] )) || skip 'no jq on PATH'

evt="${HERDR_PLUGIN_EVENT_JSON:-}"
[[ -n "$evt" ]] || exit 0
agent_status="$(print -r -- "$evt" | jq -r '.data.agent_status // .data.agentStatus // .agent_status // empty' 2>/dev/null)"
pane_id="$(print -r -- "$evt" | jq -r '.data.pane_id // .data.paneId // .pane_id // empty' 2>/dev/null)"
[[ -n "$agent_status" && -n "$pane_id" ]] || exit 0
[[ "$agent_status" == idle ]] || skip "status=$agent_status"

(( $+commands[hunk] )) || skip 'no hunk on PATH'

info="$("$herdr_bin" pane get "$pane_id" 2>/dev/null)" || skip 'pane get failed'
cwd="$(print -r -- "$info" | jq -r '.result.pane.foreground_cwd // .result.pane.cwd // empty' 2>/dev/null)" \
  || skip 'pane get parse failed'
[[ -n "$cwd" && -d "$cwd" ]] || skip "bad cwd=$cwd"

root="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)" || skip "not git repo cwd=$cwd"
root="${root:A}"

porcelain="$(git -C "$root" status --porcelain 2>/dev/null)"
[[ -n "$porcelain" ]] || skip "no changes in $root"

hunk session get --repo "$root" >/dev/null 2>&1 && skip "session live for $root"

# The hunk daemon may not track every session; fall back to herdr's own pane
# list: a live `hunk diff --watch` viewer auto-reloads, so never stack a
# second one in the same tab.
my_tab="$(print -r -- "$info" | jq -r '.result.pane.tab_id // empty' 2>/dev/null)"
if [[ -n "$my_tab" ]]; then
  existing="$("$herdr_bin" pane list 2>/dev/null | jq -r --arg tab "$my_tab" \
    '[.result.panes[]? | select(.label == "hunk" and .tab_id == $tab)][0].pane_id // empty' 2>/dev/null)"
  [[ -n "$existing" ]] && skip "hunk pane $existing already open"
fi

sha256() {
  if (( $+commands[sha256sum] )); then sha256sum "$@"; else shasum -a 256 "$@"; fi
}

# Reopen only when the diff changed since we last opened a pane for it, so a
# manually closed hunk pane stays closed until the agent produces new changes.
# Hash tracked diff AND untracked file contents (git diff can't see untracked).
sig="$( {
  print -r -- "$porcelain"
  git -C "$root" diff HEAD 2>/dev/null || git -C "$root" diff 2>/dev/null
  git -C "$root" ls-files --others --exclude-standard 2>/dev/null | while IFS= read -r f; do
    [[ -f "$root/$f" ]] && sha256 "$root/$f" 2>/dev/null
  done
} | sha256 | cut -d' ' -f1)"

state_dir="${HERDR_PLUGIN_STATE_DIR:-$HOME/.cache/hunk}"
mkdir -p "$state_dir" 2>/dev/null
key_file="$state_dir/$(print -rn -- "${root:l}" | sha256 | cut -d' ' -f1).sig"
[[ -f "$key_file" && "$(<"$key_file")" == "$sig" ]] && skip 'same sig'
print -rn -- "$sig" >"$key_file" 2>/dev/null

print -r -- "OPENING beside $pane_id in $root"
if in_tuios; then
  tuios_split_right "$pane_id" "$root" --no-focus hunk-diff.zsh && exit 0
fi
exec "$herdr_bin" plugin pane open \
  --plugin hunk --entrypoint hunk-diff \
  --placement split --direction right --no-focus \
  --target-pane "$pane_id" \
  --cwd "$root"
