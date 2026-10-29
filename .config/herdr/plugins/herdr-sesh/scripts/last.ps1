# Action: focus the most recently used open workspace other than the current one.
# Windows counterpart of last.zsh.
. (Join-Path $PSScriptRoot 'lib.ps1')

$workspaces = @(Get-Workspaces)
$current = ($workspaces | Where-Object Focused | Select-Object -First 1).Id
$openIds = @($workspaces | ForEach-Object Id)

$target = Read-History | Where-Object { $_ -ne $current -and $openIds -contains $_ } | Select-Object -First 1
if ($target) { Set-WorkspaceFocus $target; exit 0 }

Show-Toast 'no previous workspace'
