# Action: open the picker popup. Windows counterpart of open-picker.zsh.
. (Join-Path $PSScriptRoot 'lib.ps1')
Assert-Command @('fzf')

& $script:HerdrBin plugin pane open --plugin $script:PluginId --entrypoint picker-win --placement overlay
exit $LASTEXITCODE
