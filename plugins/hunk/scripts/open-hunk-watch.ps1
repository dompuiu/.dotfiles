# Toggle a live hunk diff in a split pane: OPEN if absent in the focused tab,
# FOCUS if present but unfocused, CLOSE if it is the focused pane.
# Windows counterpart of open-hunk-watch.zsh.
# Like bash `set -uo pipefail` (no -e): herdr/git calls may fail;
# check $LASTEXITCODE explicitly instead of aborting.
$ErrorActionPreference = 'Continue'
$PSNativeCommandUseErrorActionPreference = $false

. (Join-Path $PSScriptRoot 'lib.ps1')

function Get-TargetCwd {
  $ctxRaw = $env:HERDR_PLUGIN_CONTEXT_JSON
  if ($ctxRaw) {
    try {
      $ctx = ($ctxRaw | ConvertFrom-Json -ErrorAction Stop)
      foreach ($k in @('focused_pane_cwd', 'workspace_cwd', 'cwd')) {
        if ($ctx.$k -and (Test-Path -LiteralPath $ctx.$k -PathType Container)) { return $ctx.$k }
      }
    } catch {}
  }
  try {
    $panes = ((& $herdrBin pane list 2>$null) | ConvertFrom-Json -ErrorAction Stop).result.panes
    $focused = $panes | Where-Object { $_.focused } | Select-Object -First 1
    if ($focused -and $focused.cwd -and (Test-Path -LiteralPath $focused.cwd -PathType Container)) {
      return $focused.cwd
    }
  } catch {}
  return $HOME
}

function Open-Pane {
  if (Test-Tuios) {
    $anchor = Get-FocusedPaneId
    if ($anchor -and (Invoke-TuiosSplitRight $anchor (Get-TargetCwd) '--focus' 'hunk-diff.ps1')) { exit 0 }
  }
  & $herdrBin plugin pane open `
    --plugin hunk --entrypoint hunk-diff-win `
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

$hunkPane = $panes | Where-Object { $_.label -eq 'hunk' -and $_.tab_id -eq $focused.tab_id } | Select-Object -First 1
if (-not $hunkPane -or -not $hunkPane.pane_id) { Open-Pane }

$pid_ = $hunkPane.pane_id
if ($pid_ -eq $focused.pane_id) {
  & $herdrBin pane close $pid_
  exit $LASTEXITCODE
} else {
  # Plugin panes: prefer explicit focus, fall back to zoom trick from bash version.
  & $herdrBin plugin pane focus $pid_ 2>$null
  if ($LASTEXITCODE -eq 0) { exit 0 }
  & $herdrBin pane zoom $pid_ --on 2>$null | Out-Null
  & $herdrBin pane zoom $pid_ --off
  exit $LASTEXITCODE
}
