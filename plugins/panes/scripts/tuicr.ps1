# Runs INSIDE the pane (has a TTY, cwd = invoking pane's project).
# Resolve tuicr to an absolute path, then become it with any args passed
# (e.g. -w). Quitting tuicr closes the pane.
#
# The pane inherits the herdr server's PATH (frozen at server start, no profile
# runs), so interactive-shell setup like `mise activate` never applies here.
# Resolve the same way the launchers do instead of relying on PATH alone.
$ErrorActionPreference = 'Continue'
$PSNativeCommandUseErrorActionPreference = $false

function Get-TuicrPath {
  if (Get-Command tuicr -ErrorAction SilentlyContinue) {
    return (Get-Command tuicr -ErrorAction SilentlyContinue).Source
  }
  if (Get-Command mise -ErrorAction SilentlyContinue) {
    try {
      $p = (& mise which tuicr 2>$null | Select-Object -Last 1)
      if ($p -and (Test-Path -LiteralPath $p -PathType Leaf)) { return $p }
    } catch {}
  }
  $localAppData = $env:LOCALAPPDATA
  if (-not $localAppData -and $HOME) { $localAppData = Join-Path $HOME 'AppData\Local' }
  if ($localAppData) {
    # Direct exe first: it never depends on mise being on PATH, unlike the shim.
    $toolDir = Join-Path $localAppData 'mise\installs\github-agavra-tuicr'
    if (Test-Path -LiteralPath $toolDir -PathType Container) {
      $best = Get-ChildItem -LiteralPath $toolDir -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'tuicr.exe') } |
        Sort-Object Name -Descending | Select-Object -First 1
      if ($best) { return (Join-Path $best.FullName 'tuicr.exe') }
    }
    $shim = Join-Path $localAppData 'mise\shims\tuicr.exe'
    if (Test-Path -LiteralPath $shim -PathType Leaf) { return $shim }
  }
  return $null
}

$tuicr = Get-TuicrPath
if (-not $tuicr) {
  Write-Host 'tuicr not found.'
  Write-Host 'Searched PATH, `mise which tuicr`, %LOCALAPPDATA%\mise\shims and %LOCALAPPDATA%\mise\installs\github-agavra-tuicr.'
  Write-Host 'Install with: mise use -g github:agavra/tuicr@0.28.0, then restart herdr from a terminal where mise is activated.'
  Read-Host 'press Enter to close'
  exit 1
}

& $tuicr @args
exit $LASTEXITCODE
