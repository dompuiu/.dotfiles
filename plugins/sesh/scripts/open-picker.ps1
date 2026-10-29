# Action: open the picker popup. Windows counterpart of open-picker.zsh.
. (Join-Path $PSScriptRoot 'lib.ps1')
Assert-Command @('fzf')

# herdr's overlay covers the tab; tuios's is a smaller float, its zoomed matches.
$placement = if (Test-Tuios) { 'zoomed' } else { 'overlay' }

& $script:HerdrBin plugin pane open --plugin $script:PluginId --entrypoint picker-win --placement $placement
exit $LASTEXITCODE
