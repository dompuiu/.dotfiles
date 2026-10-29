# Toggle the agent-idle autodiff on/off and toast the new state.
# Keep going on non-zero exits; check $LASTEXITCODE explicitly.
$ErrorActionPreference = 'Continue'
$PSNativeCommandUseErrorActionPreference = $false

$herdrBin = if ($env:HERDR_BIN_PATH) { $env:HERDR_BIN_PATH } else { 'herdr' }
$cfgDir = $env:HERDR_PLUGIN_CONFIG_DIR
if (-not $cfgDir) {
  $cfgDir = (& $herdrBin plugin config-dir hunk 2>$null | Select-Object -Last 1).Trim()
}
if (-not $cfgDir) { exit 1 }
New-Item -ItemType Directory -Force -Path $cfgDir 2>$null | Out-Null

$flag = Join-Path $cfgDir 'autodiff-off'
if (Test-Path -LiteralPath $flag) {
  Remove-Item -LiteralPath $flag -Force
  $state = 'ON'
} else {
  New-Item -ItemType File -Force -Path $flag 2>$null | Out-Null
  $state = 'OFF'
}

& $herdrBin notification show "hunk autodiff: $state" --position top-right
exit $LASTEXITCODE
