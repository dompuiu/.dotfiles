<#
.SYNOPSIS
  Link every herdr plugin kept in this repo (Windows port of bin/herdr-link-plugins).

.DESCRIPTION
  Any directory under .config/herdr/plugins containing a herdr-plugin.toml is
  passed to `herdr plugin link`, so herdr loads it straight from the repo.
#>
$ErrorActionPreference = 'Continue'
$PSNativeCommandUseErrorActionPreference = $false

$pluginsDir = Join-Path (Split-Path -Parent $PSScriptRoot) '.config/herdr/plugins'

if (-not (Get-Command herdr -ErrorAction SilentlyContinue)) {
  Write-Error 'herdr not found on PATH'
  exit 1
}

$status = 0
foreach ($dir in Get-ChildItem -LiteralPath $pluginsDir -Directory) {
  if (-not (Test-Path -LiteralPath (Join-Path $dir.FullName 'herdr-plugin.toml'))) { continue }
  $out = (herdr plugin link $dir.FullName 2>&1 | Out-String)
  if ($LASTEXITCODE -eq 0 -and $out -notmatch '"error"') {
    Write-Output "linked $($dir.Name)"
  } else {
    Write-Warning "failed $($dir.Name): $out"
    $status = 1
  }
}

exit $status
