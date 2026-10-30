#!/usr/bin/env zsh
# Action: open the picker popup.
source "${0:A:h}/lib.zsh"
need jq fzf

# herdr's overlay covers the tab; tuios's is a smaller float, its zoomed matches.
placement=overlay
in_tuios && placement=zoomed

"$herdr_bin" plugin pane open --plugin "$plugin_id" --entrypoint picker --placement "$placement" --focus
