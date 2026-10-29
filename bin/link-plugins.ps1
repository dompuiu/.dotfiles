<#
.SYNOPSIS
  Link every plugin kept in this repo into herdr and/or tuios (Windows port of bin/link-plugins).

.DESCRIPTION
  Any directory under plugins/ containing a herdr-plugin.toml is linked into
  herdr and/or tuios, whichever is installed, so they load straight from the
  repo. tuios also reads herdr's plugin list, so when herdr is present the
  plugins are only enabled in tuios; otherwise tuios links them itself.
  Plugins linked from this repo that no longer exist here (renamed, moved or
  deleted) are unlinked first. Run from a terminal outside tuios.
#>
$ErrorActionPreference = 'Continue'
$PSNativeCommandUseErrorActionPreference = $false

$repoRoot = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$pluginsDir = Join-Path $repoRoot 'plugins'

$hasHerdr = [bool](Get-Command herdr -ErrorAction SilentlyContinue)
$hasTuios = [bool](Get-Command tuios -ErrorAction SilentlyContinue)
if (-not $hasHerdr -and -not $hasTuios) {
  Write-Error 'neither herdr nor tuios found on PATH'
  exit 1
}
if (-not $hasHerdr) { Write-Output 'herdr not found, skipping it' }
if (-not $hasTuios) { Write-Output 'tuios not found, skipping it' }

$status = 0
function Invoke-Plugin([string]$HostName, [string]$Verb, [string]$Name, [scriptblock]$Cmd) {
  $out = (& $Cmd 2>&1 | Out-String)
  if ($LASTEXITCODE -eq 0 -and $out -notmatch '"error"') {
    Write-Output "${HostName}: $Verb $Name"
  } else {
    Write-Warning "${HostName}: failed to $Verb ${Name}: $out"
    $script:status = 1
  }
}

function Get-FullPath([string]$Path) { [IO.Path]::GetFullPath($Path).TrimEnd('\', '/') }

$current = foreach ($dir in Get-ChildItem -LiteralPath $pluginsDir -Directory) {
  $manifest = Join-Path $dir.FullName 'herdr-plugin.toml'
  if (-not (Test-Path -LiteralPath $manifest)) { continue }
  $m = Select-String -LiteralPath $manifest -Pattern '^id\s*=\s*"([^"]+)"' | Select-Object -First 1
  if ($m) { [pscustomobject]@{ Id = $m.Matches[0].Groups[1].Value; Dir = Get-FullPath $dir.FullName } }
}

# A linked plugin is stale when it points into this repo but its id and folder
# don't match a plugin that is in the repo now.
function Test-Stale([string]$Id, [string]$Dir) {
  if (-not $Dir) { return $false }
  $full = Get-FullPath $Dir
  if (-not $full.StartsWith($repoRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { return $false }
  return -not ($current | Where-Object { $_.Id -eq $Id -and $_.Dir -ieq $full })
}

# Handle tuios first: plugins it reads from herdr vanish once herdr unlinks them.
$tuiosStale = @()
if ($hasTuios) {
  $list = (tuios plugins list --json 2>$null | Out-String)
  if ($list.Trim()) {
    $tuiosStale = @($list | ConvertFrom-Json | Where-Object {
      $_.manifest_path -and (Test-Stale $_.plugin_id (Split-Path -Parent $_.manifest_path))
    })
  }
}

foreach ($p in $tuiosStale) {
  $id = $p.plugin_id
  if ($p.origin -eq 'herdr') { Invoke-Plugin 'tuios' 'disabled' $id { tuios plugins disable $id } }
  else { Invoke-Plugin 'tuios' 'unlinked' $id { tuios plugins unlink $id } }
}

if ($hasHerdr) {
  foreach ($line in (herdr plugin list 2>$null)) {
    if ($line -match '^- (\S+) .*\[local:(.*)\]$' -and (Test-Stale $Matches[1] $Matches[2])) {
      $id = $Matches[1]
      Invoke-Plugin 'herdr' 'unlinked' $id { herdr plugin unlink $id }
    }
  }
}

foreach ($p in $current) {
  $id = $p.Id; $path = $p.Dir
  if ($hasHerdr) { Invoke-Plugin 'herdr' 'linked' $id { herdr plugin link $path } }
  if ($hasTuios) {
    if ($hasHerdr) { Invoke-Plugin 'tuios' 'enabled' $id { tuios plugins enable $id } }
    else { Invoke-Plugin 'tuios' 'linked' $id { tuios plugins link $path --enable } }
  }
}

exit $status
