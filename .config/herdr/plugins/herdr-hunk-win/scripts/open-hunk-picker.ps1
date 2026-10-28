# Action launcher (runs detached, no TTY): open the picker pane in the
# invoking pane's project. Usage: open-hunk-picker.ps1 [split|tab]
# Port of herdr-hunk scripts/open-hunk-picker.sh for Windows.
$ErrorActionPreference = 'Continue'
$PSNativeCommandUseErrorActionPreference = $false

$herdrBin = if ($env:HERDR_BIN_PATH) { $env:HERDR_BIN_PATH } else { 'herdr' }
$placement = if ($args.Count -ge 1 -and $args[0]) { $args[0] } else { 'split' }

# Root the picker at the invoking pane's directory, not the plugin install
# dir. Context JSON is injected by herdr on action invoke; fall back to the
# focused pane's cwd, then HOME.
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

$openArgs = @('plugin', 'pane', 'open',
  '--plugin', 'herdr-hunk-win', '--entrypoint', 'hunk-picker',
  '--placement', $placement, '--focus',
  '--cwd', (Get-TargetCwd))
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
