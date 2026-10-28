<#
.SYNOPSIS
  Link dotfiles from this repo into $HOME (Windows port of bin/install).

.DESCRIPTION
  Mirrors bin/install: every file in the repo (except .git, bin, README*,
  and .config/fish internals) is symlinked to the matching path under $HOME.
  Fish paths are linked as whole dirs / key files, exactly like bin/install.

  Also ensures user-level XDG_CONFIG_HOME=$HOME\.config so tools like Neovim
  use ~/.config (otherwise ~/.config/nvim is ignored on Windows).

.PARAMETER Force
  Run clean.ps1 first (removes previously created links), and replace any
  existing destination with the correct link.

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
        if ($item.Name -like 'README*') { continue }
        if ($rel.StartsWith('.config/fish/')) { continue }
        $sources.Add($item.FullName)
    }
    # Fish specials, mirroring bin/install (dirs linked whole, not per-file).
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

if ($Force) {
    & (Join-Path $PSScriptRoot 'clean.ps1') -WhatIf:$WhatIfPreference
}

$linked = 0; $skipped = 0
foreach ($source in (Get-DotfileSources $RepoRoot)) {
    $destination = Join-Path $HOME ([IO.Path]::GetRelativePath($RepoRoot, $source))
    $existing = Get-Item $destination -ErrorAction SilentlyContinue
    if ($existing) {
        $targets = @($existing.Target) | Where-Object { $_ }
        if ($existing.LinkType -and ($targets -contains $source)) {
            Write-Host "Exists (ok): $destination"
            $skipped++
            continue
        }
        if ($Force) {
            if ($PSCmdlet.ShouldProcess($destination, 'Remove existing and re-link')) {
                Remove-Item $destination -Recurse -Force
                $existing = $null
            } else { $skipped++; continue }
        } else {
            Write-Warning "Exists, skipping (re-run with -Force to replace): $destination"
            $skipped++
            continue
        }
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

$localNvim = Join-Path $env:LOCALAPPDATA 'nvim'
if ((Test-Path $localNvim) -and (-not $SkipXdg)) {
    Write-Warning "$localNvim still exists. With XDG_CONFIG_HOME set, nvim prefers the .config path instead. Verify the new location is picked up, then remove the old link."
}

Write-Host "Done. Linked: $linked, skipped: $skipped."
