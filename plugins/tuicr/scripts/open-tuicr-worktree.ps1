# Toggle a tuicr review of uncommitted changes in a split pane: OPEN if absent in the focused tab,
# FOCUS if present but unfocused, CLOSE if it is the focused pane.
# Windows counterpart of open-tuicr-worktree.zsh.
# Like bash `set -uo pipefail` (no -e): herdr/git calls may fail;
# check $LASTEXITCODE explicitly instead of aborting.
$ErrorActionPreference = 'Continue'
$PSNativeCommandUseErrorActionPreference = $false

. (Join-Path $PSScriptRoot 'lib.ps1')

function Open-Pane {
  if (Test-Tuios) {
    $anchor = Get-FocusedPaneId
    if ($anchor -and (Invoke-TuiosSplitRight $anchor (Get-TargetCwd) '--focus' 'tuicr.ps1' @('-w'))) { exit 0 }
  }
  & $herdrBin plugin pane open `
    --plugin tuicr --entrypoint tuicr-worktree-win `
    --placement split --direction right --focus `
    --cwd (Get-TargetCwd)
  exit $LASTEXITCODE
}

$panesRaw = (& $herdrBin pane list 2>$null)
if ($LASTEXITCODE -ne 0 -or -not $panesRaw) { Open-Pane }
try { $panes = ($panesRaw | ConvertFrom-Json -ErrorAction Stop).result.panes }
catch { Open-Pane }
if (-not $panes) { Open-Pane }

$focused = $panes | Where-Object { $_.focused } | Select-Object -First 1
if (-not $focused) { Open-Pane }

$tuicrPane = $panes | Where-Object { $_.label -eq 'tuicr' -and $_.tab_id -eq $focused.tab_id } | Select-Object -First 1
if (-not $tuicrPane -or -not $tuicrPane.pane_id) { Open-Pane }

$pid_ = $tuicrPane.pane_id
if ($pid_ -eq $focused.pane_id) {
  & $herdrBin pane close $pid_
  exit $LASTEXITCODE
} else {
  # Plugin panes: prefer explicit focus, fall back to zoom trick from the zsh version.
  & $herdrBin plugin pane focus $pid_ 2>$null
  if ($LASTEXITCODE -eq 0) { exit 0 }
  & $herdrBin pane zoom $pid_ --on 2>$null | Out-Null
  & $herdrBin pane zoom $pid_ --off
  exit $LASTEXITCODE
}
