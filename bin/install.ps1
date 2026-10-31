<#
.SYNOPSIS
  Link dotfiles from this repo into $HOME (Windows port of bin/install).

.DESCRIPTION
  Mirrors bin/install: every file in the repo (except .git, bin, plugins and README*)
  is symlinked to the matching path under $HOME. Safe to re-run: existing
  links are kept, and anything else in the way is skipped and listed.

  Also ensures user-level XDG_CONFIG_HOME=$HOME\.config so tools like Neovim
  use ~/.config (otherwise ~/.config/nvim is ignored on Windows).

.PARAMETER Force
  Run clean.ps1 first (removes previously created links). Real files in the
  way are never deleted; they are skipped and listed.

.PARAMETER SkipXdg
  Do not touch the XDG_CONFIG_HOME environment variable.
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Force,
    [switch]$SkipXdg
)

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

if ($Force) {
    & (Join-Path $PSScriptRoot 'clean.ps1') -WhatIf:$WhatIfPreference
}

function Resolve-RealPath {
    # Follows symlinks/junctions in every component of $Path, like `readlink -f`.
    param([string]$Path)
    $full = [IO.Path]::GetFullPath($Path)
    $root = [IO.Path]::GetPathRoot($full)
    $current = $root
    foreach ($part in $full.Substring($root.Length).Split([IO.Path]::DirectorySeparatorChar, [StringSplitOptions]::RemoveEmptyEntries)) {
        $current = Join-Path $current $part
        $item = Get-Item -LiteralPath $current -Force -ErrorAction SilentlyContinue
        if ($item -and $item.LinkType) {
            $target = $item.ResolveLinkTarget($true)
            if ($target) { $current = $target.FullName }
        }
    }
    return $current
}

$linked = 0
$skipped = New-Object Collections.Generic.List[string]
foreach ($source in (Get-DotfileSources $RepoRoot)) {
    $destination = Join-Path $HOME ([IO.Path]::GetRelativePath($RepoRoot, $source))
    $existing = Get-Item -LiteralPath $destination -Force -ErrorAction SilentlyContinue
    if ($existing) {
        # Already linked (directly or through a linked parent folder).
        if ((Test-Path -LiteralPath $destination) -and
            ((Resolve-RealPath $destination) -eq (Resolve-RealPath $source))) { continue }
        # Leave anything else in the way alone: real files, or links pointing elsewhere.
        Write-Warning "Skipping ${destination}: it already exists and is not a link to $source."
        $skipped.Add($destination)
        continue
    }
    $parent = Split-Path $destination -Parent
    if (-not (Test-Path $parent)) {
        if ($PSCmdlet.ShouldProcess($parent, 'Create directory')) {
            New-Item -ItemType Directory -Force -Path $parent | Out-Null
        }
    }
    if ($PSCmdlet.ShouldProcess($destination, "Link to $source")) {
        New-Item -ItemType SymbolicLink -Path $destination -Target $source | Out-Null
        Write-Host "Linked: $source --> $destination"
        $linked++
    }
}

if (-not $SkipXdg) {
    $xdgTarget = Join-Path $HOME '.config'
    $userXdg = [Environment]::GetEnvironmentVariable('XDG_CONFIG_HOME', 'User')
    if (-not $userXdg) {
        if ($PSCmdlet.ShouldProcess('XDG_CONFIG_HOME (user)', "Set to $xdgTarget")) {
            [Environment]::SetEnvironmentVariable('XDG_CONFIG_HOME', $xdgTarget, 'User')
            $env:XDG_CONFIG_HOME = $xdgTarget
            Write-Host "Set user XDG_CONFIG_HOME=$xdgTarget. Restart terminals for it to take effect."
        }
    } elseif ($userXdg -ne $xdgTarget) {
        Write-Warning "XDG_CONFIG_HOME is already '$userXdg' (expected '$xdgTarget'); leaving it alone."
        $env:XDG_CONFIG_HOME = $userXdg
    } else {
        $env:XDG_CONFIG_HOME = $xdgTarget
    }
}

# Windows pwsh reads its profile from Documents, not ~/.config, so load the
# repo profile from there. Existing profile content is kept.
$repoProfile = Join-Path $HOME '.config\powershell\Microsoft.PowerShell_profile.ps1'
$profileLoader = '. "$HOME\.config\powershell\Microsoft.PowerShell_profile.ps1"'
$userProfile = $PROFILE.CurrentUserCurrentHost
if ($IsWindows -and $userProfile -and ($userProfile -ne $repoProfile)) {
    $hasLoader = (Test-Path $userProfile) -and
        (Select-String -LiteralPath $userProfile -SimpleMatch $profileLoader -Quiet)
    if (-not $hasLoader -and $PSCmdlet.ShouldProcess($userProfile, 'Add loader for repo profile')) {
        New-Item -ItemType Directory -Force -Path (Split-Path $userProfile -Parent) | Out-Null
        Add-Content -LiteralPath $userProfile -Value $profileLoader
        Write-Host "Added repo profile loader to $userProfile"
    }
}

$localNvim = Join-Path $env:LOCALAPPDATA 'nvim'
if ((Test-Path $localNvim) -and (-not $SkipXdg)) {
    Write-Warning "$localNvim still exists. With XDG_CONFIG_HOME set, nvim prefers the .config path instead. Verify the new location is picked up, then remove the old link."
}

Write-Host "Done. Linked: $linked."
if ($skipped.Count -gt 0) {
    Write-Host ""
    Write-Host "Skipped $($skipped.Count) path(s) that are in the way. Move them aside and run again:"
    $skipped | ForEach-Object { Write-Host "  $_" }
    exit 1
}
