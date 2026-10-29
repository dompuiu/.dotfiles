#!/usr/bin/env zsh
# Action: open the picker popup.
source "${0:A:h}/lib.zsh"
need jq fzf

"$herdr_bin" plugin pane open --plugin "$plugin_id" --entrypoint picker --placement overlay
