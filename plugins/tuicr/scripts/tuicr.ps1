# Runs INSIDE the pane (has a TTY, cwd = invoking pane's project).
# Become tuicr with any args passed (e.g. -w). Quitting tuicr closes the pane.
# Windows counterpart of tuicr.zsh.
$ErrorActionPreference = 'Continue'
$PSNativeCommandUseErrorActionPreference = $false

if (-not (Get-Command tuicr -ErrorAction SilentlyContinue)) {
  Write-Host 'tuicr not found on PATH'
  Read-Host 'press Enter to close'
  exit 1
}

& tuicr @args
exit $LASTEXITCODE
