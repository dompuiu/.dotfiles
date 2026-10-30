# Action launcher (runs detached, no TTY): open tuicr in the invoking pane's
# project. Usage: open-tuicr.ps1 [split|tab]
# Windows counterpart of open-tuicr.zsh.
$ErrorActionPreference = 'Continue'
$PSNativeCommandUseErrorActionPreference = $false

. (Join-Path $PSScriptRoot 'lib.ps1')
$placement = if ($args.Count -ge 1 -and $args[0]) { $args[0] } else { 'split' }

if (-not (Get-TuicrPath)) {
  & $herdrBin notification show 'tuicr not found: mise use -g github:agavra/tuicr@0.28.0, then restart herdr from an activated terminal' --position top-right 2>$null | Out-Null
  exit 1
}

$cwd = Get-TargetCwd

# Re-pressing the key in split mode: close any existing tuicr pane in the
# focused tab so tuicr starts fresh instead of stacking splits.
if ($placement -eq 'split') {
  try {
    $panes = ((& $herdrBin pane list 2>$null) | ConvertFrom-Json -ErrorAction Stop).result.panes
    $focused = $panes | Where-Object { $_.focused } | Select-Object -First 1
    if ($focused) {
      $panes | Where-Object { $_.label -eq 'tuicr' -and $_.tab_id -eq $focused.tab_id -and $_.pane_id } |
        ForEach-Object { & $herdrBin pane close $_.pane_id 2>$null | Out-Null }
    }
  } catch {}
}

if ($placement -eq 'split' -and (Test-Tuios)) {
  $anchor = Get-FocusedPaneId
  if ($anchor -and (Invoke-TuiosSplitRight $anchor $cwd '--focus' 'tuicr.ps1')) { exit 0 }
}

$openArgs = @('plugin', 'pane', 'open',
  '--plugin', 'tuicr', '--entrypoint', 'tuicr-win',
  '--placement', $placement, '--focus',
  '--cwd', $cwd)
if ($placement -eq 'split') { $openArgs += @('--direction', 'right') }

$openOut = (& $herdrBin @openArgs 2>$null | Out-String)
$openExit = $LASTEXITCODE
if ($openOut) { Write-Output $openOut }
if ($openExit -ne 0) { exit $openExit }

# --focus updates server focus but does not navigate attached clients
# (see tsk open-board.ps1). Explicit `tab focus` does, so parse the
# open response (.result.plugin_pane.pane.tab_id) and focus it.
$tabId = $null
$paneId = $null
try {
  $j = ($openOut | ConvertFrom-Json -ErrorAction Stop)
  $pp = $j.result.plugin_pane
  if (-not $pp) { $pp = $j.result }
  if ($pp.pane -and $pp.pane.tab_id) { $tabId = $pp.pane.tab_id; $paneId = $pp.pane.pane_id }
  elseif ($pp.tab_id) { $tabId = $pp.tab_id }
  elseif ($pp.pane_id) { $paneId = $pp.pane_id }
  if (-not $tabId -and $j.result.tab -and $j.result.tab.tab_id) { $tabId = $j.result.tab.tab_id }
} catch {}

if (-not $tabId -and $paneId) {
  try {
    $info = (& $herdrBin pane get $paneId 2>$null | ConvertFrom-Json -ErrorAction Stop)
    $tabId = $info.result.pane.tab_id
  } catch {}
}
if ($placement -eq 'tab' -and $tabId) {
  & $herdrBin tab focus $tabId | Out-Null
  exit $LASTEXITCODE
}
exit 0
