# Runs INSIDE the pane (has a TTY, cwd = invoking pane's project).
# Become tuicr with any args passed (e.g. -w). Quitting tuicr closes the pane.
# Windows counterpart of tuicr.zsh.
$ErrorActionPreference = 'Continue'
$PSNativeCommandUseErrorActionPreference = $false

. (Join-Path $PSScriptRoot 'lib.ps1')

# The pane inherits the herdr server's PATH (no profile runs), so resolve
# tuicr the same way the launchers do instead of relying on PATH alone.
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
