#!/usr/bin/env zsh
# Toggle the agent-idle autodiff on/off and toast the new state.
setopt pipe_fail no_unset

herdr_bin="${HERDR_BIN_PATH:-herdr}"
cfg_dir="${HERDR_PLUGIN_CONFIG_DIR:-}"
[[ -n "$cfg_dir" ]] || cfg_dir="$("$herdr_bin" plugin config-dir hunk 2>/dev/null | tail -n 1)"
[[ -n "$cfg_dir" ]] || exit 1
mkdir -p "$cfg_dir" 2>/dev/null

flag="$cfg_dir/autodiff-off"
if [[ -e "$flag" ]]; then
  rm -f "$flag"
  state=ON
else
  : >"$flag"
  state=OFF
fi

exec "$herdr_bin" notification show "hunk autodiff: $state" --position top-right
