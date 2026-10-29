# Event hook (workspace.focused / workspace.closed): keep an MRU list of
# workspace ids, most recent first. Windows counterpart of track.zsh.
. (Join-Path $PSScriptRoot 'lib.ps1')

if (-not $env:HERDR_PLUGIN_EVENT_JSON) { exit 0 }
try { $evt = $env:HERDR_PLUGIN_EVENT_JSON | ConvertFrom-Json -ErrorAction Stop } catch { exit 0 }
$kind = if ($evt.data.type) { $evt.data.type } else { "$($evt.event)" }
$wsId = if ($evt.data.workspace_id) { $evt.data.workspace_id } else { $evt.workspace_id }
if (-not $wsId) { exit 0 }

$ids = @(Read-History | Where-Object { $_ -ne $wsId })
if ($kind -notlike '*closed*') { $ids = @($wsId) + $ids }

$hist = Get-HistoryFile
$tmp = "$hist.$PID"
$ids | Select-Object -First 50 | Set-Content -LiteralPath $tmp
Move-Item -LiteralPath $tmp -Destination $hist -Force
