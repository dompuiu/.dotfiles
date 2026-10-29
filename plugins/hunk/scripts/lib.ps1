# Shared helpers for hunk pwsh scripts. Dot-source, don't execute.
# Windows counterpart of lib.zsh.

$herdrBin = if ($env:HERDR_BIN_PATH) { $env:HERDR_BIN_PATH } else { 'herdr' }
$hunkRoot = Split-Path -Parent $PSScriptRoot

# tuios runs herdr plugins through a herdr-compatible CLI of its own.
function Test-Tuios {
  [bool]($env:TUIOS_PLUGIN_ID -or $env:TUIOS_SOCKET -or $herdrBin -like '*tuios*')
}

function Get-FocusedPaneId {
  try {
    $panes = ((& $herdrBin pane list 2>$null) | ConvertFrom-Json -ErrorAction Stop).result.panes
    ($panes | Where-Object { $_.focused } | Select-Object -First 1).pane_id
  } catch { $null }
}

# Pane with the rightmost edge in the tab of $PaneId (tallest on ties).
function Get-RightmostPaneId([string]$PaneId) {
  try {
    $layout = ((& $herdrBin pane layout --pane $PaneId 2>$null) | ConvertFrom-Json -ErrorAction Stop).result.layout
    ($layout.panes | Where-Object { $_.rect } |
      Sort-Object { $_.rect.x + $_.rect.width }, { $_.rect.height } |
      Select-Object -Last 1).pane_id
  } catch { $null }
}

# tuios ignores --direction on `plugin pane open`, and on `pane split` as soon
# as --cwd or --env is passed. So split plain, label the pane like herdr does,
# then cd and run the pane script in its shell. Returns $true on success.
function Invoke-TuiosSplitRight([string]$Anchor, [string]$Cwd, [string]$Focus, [string]$Script) {
  $target = Get-RightmostPaneId $Anchor
  if (-not $target) { $target = $Anchor }
  try {
    $id = ((& $herdrBin pane split --pane $target --direction right $Focus 2>$null) |
      ConvertFrom-Json -ErrorAction Stop).result.pane.pane_id
  } catch { return $false }
  if (-not $id) { return $false }
  & $herdrBin pane rename $id hunk 2>$null | Out-Null
  $q = { param($s) "'" + ($s -replace "'", "''") + "'" }
  $scriptPath = Join-Path (Join-Path $hunkRoot 'scripts') $Script
  $cmd = "Set-Location -LiteralPath $(& $q $Cwd); pwsh -NoLogo -NoProfile -ExecutionPolicy Bypass -File $(& $q $scriptPath); exit"
  & $herdrBin pane run $id $cmd 2>$null | Out-Null
  return $true
}
