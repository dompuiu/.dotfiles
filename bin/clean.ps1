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
        if ($rel -eq 'plugins' -or $rel.StartsWith('plugins/')) { continue }
        if ($item.Name -like 'README*') { continue }
        $sources.Add($item.FullName)
    }
    return $sources
}

function Test-PathUnderRoot {
    param([string]$Path, [string]$Root)
    $rootWithSep = $Root.TrimEnd('\', '/') + [IO.Path]::DirectorySeparatorChar
    return $Path.StartsWith($rootWithSep, [StringComparison]::OrdinalIgnoreCase)
}

function Test-TargetInRepo {
    param([string]$Target, [string]$LinkPath, [string]$Root)
    if (-not $Target) { return $false }
    # Relative link targets are relative to the link's own directory.
    $full = if ([IO.Path]::IsPathRooted($Target)) { $Target } else { Join-Path (Split-Path $LinkPath -Parent) $Target }
    return Test-PathUnderRoot ([IO.Path]::GetFullPath($full)) $Root
}

function Get-LinkedParent {
    # Returns the outermost directory between $HOME and $Path that is a
    # symlink/junction, or $null. Deleting through it could remove repo files.
    param([string]$Path)
    $homeFull = [IO.Path]::GetFullPath($HOME).TrimEnd('\', '/')
    $found = $null
    $dir = Split-Path $Path -Parent
    while ($dir -and $dir.Length -gt $homeFull.Length) {
        $item = Get-Item $dir -Force -ErrorAction SilentlyContinue
        if ($item -and $item.LinkType) { $found = $item }
        $dir = Split-Path $dir -Parent
    }
    return $found
}

$removed = 0
$destParents = New-Object Collections.Generic.HashSet[string]
$handledParents = New-Object Collections.Generic.HashSet[string]([StringComparer]::OrdinalIgnoreCase)

foreach ($source in (Get-DotfileSources $RepoRoot)) {
    $destination = Join-Path $HOME ([IO.Path]::GetRelativePath($RepoRoot, $source))
    $linkedParent = Get-LinkedParent $destination
    if ($linkedParent) {
        $parentPath = $linkedParent.FullName
        if ($handledParents.Add($parentPath)) {
            $ours = $false
            foreach ($t in @($linkedParent.Target)) {
                if (Test-TargetInRepo $t $parentPath $RepoRoot) { $ours = $true; break }
            }
            if ($ours) {
                if ($PSCmdlet.ShouldProcess($parentPath, 'Remove directory link')) {
                    # Delete() removes only the link, never the repo contents behind it.
                    $linkedParent.Delete()
                    Write-Host "Removed directory link: $parentPath"
                    $removed++
                }
            } else {
                Write-Warning "Parent directory links elsewhere, keeping: $parentPath"
            }
        }
        continue
    }
    $item = Get-Item $destination -Force -ErrorAction SilentlyContinue
    if (-not $item) { continue }
    [void]$destParents.Add((Split-Path $destination -Parent))
    if ($item.LinkType) {
        $ours = $false
        foreach ($t in @($item.Target)) {
            if (Test-TargetInRepo $t $destination $RepoRoot) { $ours = $true; break }
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

# Sweep broken symlinks under ~/.config that point into this repo.
$configHome = Join-Path $HOME '.config'
if (Test-Path $configHome) {
    foreach ($item in (Get-ChildItem -Path $configHome -Recurse -Force -ErrorAction SilentlyContinue)) {
        if ($item.LinkType -and (-not (Test-Path $item.FullName))) {
            $ours = $false
            foreach ($t in @($item.Target)) {
                if (Test-TargetInRepo $t $item.FullName $RepoRoot) { $ours = $true; break }
            }
            if (-not $ours) { continue }
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
