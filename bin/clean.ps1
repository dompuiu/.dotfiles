<#
.SYNOPSIS
  Remove dotfile links created by install.ps1 (Windows port of bin/clean).

.DESCRIPTION
  Mirrors bin/clean: for every source path install.ps1 would link, remove the
  matching destination under $HOME -- but only if it is a symlink/junction
  pointing back into this repo (real files are kept, with a warning).
  Also sweeps broken symlinks under ~/.config and prunes directories left
  empty by link removal.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))

function Get-DotfileSources {
    param([string]$Root)
    $sources = New-Object Collections.Generic.List[string]
    foreach ($item in (Get-ChildItem -Path $Root -Recurse -Force -File)) {
        $rel = [IO.Path]::GetRelativePath($Root, $item.FullName).Replace('\', '/')
        if ($rel -eq '.git' -or $rel.StartsWith('.git/')) { continue }
        if ($rel -eq 'bin' -or $rel.StartsWith('bin/')) { continue }
        if ($item.Name -like 'README*') { continue }
        if ($rel.StartsWith('.config/fish/')) { continue }
        $sources.Add($item.FullName)
    }
    foreach ($p in @(
        '.config/fish/functions', '.config/fish/completions', '.config/fish/conf.d',
        '.config/fish/themes', '.config/fish/config.fish', '.config/fish/environment.fish',
        '.config/fish/fish_plugins'
    )) {
        $full = Join-Path $Root $p
        if (Test-Path $full) { $sources.Add((Get-Item $full).FullName) }
    }
    return $sources
}

function Test-TargetInRepo {
    param([string]$Target, [string]$Root)
    if (-not $Target) { return $false }
    try {
        $resolved = (Resolve-Path $Target -ErrorAction Stop).Path
        return $resolved.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase)
    } catch {
        # Dangling link: fall back to the raw target text.
        $full = if ([IO.Path]::IsPathRooted($Target)) { $Target } else { $Target }
        return $full.StartsWith($Root, [StringComparison]::OrdinalIgnoreCase)
    }
}

$removed = 0
$destParents = New-Object Collections.Generic.HashSet[string]

foreach ($source in (Get-DotfileSources $RepoRoot)) {
    $destination = Join-Path $HOME ([IO.Path]::GetRelativePath($RepoRoot, $source))
    [void]$destParents.Add((Split-Path $destination -Parent))
    $item = Get-Item $destination -ErrorAction SilentlyContinue
    if (-not $item) { continue }
    if ($item.LinkType) {
        $ours = $false
        foreach ($t in @($item.Target)) {
            if (Test-TargetInRepo $t $RepoRoot) { $ours = $true; break }
        }
        if ($ours) {
            if ($PSCmdlet.ShouldProcess($destination, 'Remove link')) {
                Remove-Item $destination -Force
                Write-Host "Removed link: $destination"
                $removed++
            }
        } else {
            Write-Warning "Symlink points elsewhere, keeping: $destination"
        }
    } else {
        Write-Warning "Not a symlink, keeping: $destination"
    }
}

# Sweep broken symlinks under ~/.config (bash clean does this for nvim).
$configHome = Join-Path $HOME '.config'
if (Test-Path $configHome) {
    foreach ($item in (Get-ChildItem -Path $configHome -Recurse -Force -ErrorAction SilentlyContinue)) {
        if ($item.LinkType -and (-not (Test-Path $item.FullName))) {
            if ($PSCmdlet.ShouldProcess($item.FullName, 'Remove broken link')) {
                Remove-Item $item.FullName -Force
                Write-Host "Removed broken link: $($item.FullName)"
                $removed++
            }
        }
    }
}

# Prune directories left empty by link removal, deepest first.
$ordered = $destParents | Sort-Object -Property Length -Descending
foreach ($dir in $ordered) {
    if (-not (Test-Path $dir)) { continue }
    if (-not [IO.Path]::GetFullPath($dir).StartsWith([IO.Path]::GetFullPath($HOME), [StringComparison]::OrdinalIgnoreCase)) { continue }
    $children = Get-ChildItem -Path $dir -Force -ErrorAction SilentlyContinue
    if (-not $children) {
        if ($PSCmdlet.ShouldProcess($dir, 'Remove empty directory')) {
            Remove-Item $dir -Force
            Write-Host "Removed empty directory: $dir"
        }
    }
}

Write-Host "Done. Removed: $removed."
