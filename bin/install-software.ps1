<#
.SYNOPSIS
  Install or update the software the dotfiles need on Windows.

.DESCRIPTION
  Tries each source in order: winget first, then mise for Node, Python,
  Rust, herdr, tuios, opencode, tree-sitter and rtk, and hand-installs only
  the last resort (PowerShell 7, tuicr), the FiraCode Nerd Font and the npx
  agent skills.
  Node, Python, Rust and fnm previously installed with winget are removed so
  there is one copy. Safe to re-run: missing tools are installed and
  installed ones are upgraded.

  Not handled here: LazyVim (the Neovim config in this repo) and zi (installed
  by .config/zsh/.zshrc, so run bin/install-software inside WSL).

.PARAMETER InstallOnly
  Install what is missing; leave installed tools alone (also skips the winget
  uninstalls below).

.PARAMETER SkipOptional
  Skip the optional tools (pnpm, Rust via mise).

.PARAMETER SkipSkills
  Skip the npx agent skills.

.PARAMETER SkipFont
  Do not install the FiraCode Nerd Font.

.PARAMETER WithWsl
  After the Windows install, run bin/install-software inside the default WSL
  distribution.

.EXAMPLE
  .\bin\install-software.ps1

.EXAMPLE
  .\bin\install-software.ps1 -WhatIf
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$InstallOnly,
    [switch]$SkipOptional,
    [switch]$SkipSkills,
    [switch]$SkipFont,
    [switch]$WithWsl
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$onWindows = $true
if (Get-Variable -Name IsWindows -ErrorAction SilentlyContinue) { $onWindows = $IsWindows }
if (-not $onWindows) {
    throw 'This script is for Windows. Use bin/install-software on macOS or Linux.'
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    throw 'winget was not found. Install App Installer from the Microsoft Store, then run this again.'
}

$script:Ok = New-Object Collections.Generic.List[string]
$script:Failed = New-Object Collections.Generic.List[string]

function Invoke-Action {
    param([string]$Description, [scriptblock]$Action)
    if ($WhatIfPreference) { Write-Host "would: $Description"; return }
    Write-Host "==> $Description"
    try {
        & $Action
        $script:Ok.Add($Description)
    } catch {
        $script:Failed.Add($Description)
        Write-Warning "Failed: $Description - $($_.Exception.Message)"
    }
}

function Invoke-Native {
    param([string]$Description, [string]$FilePath, [string[]]$Arguments = @())
    if ($WhatIfPreference) { Write-Host "would: $Description"; return }
    Write-Host "==> $Description"
    try {
        & $FilePath @Arguments
        $code = $LASTEXITCODE
    } catch {
        $script:Failed.Add($Description)
        Write-Warning "Failed: $Description - $($_.Exception.Message)"
        return
    }
    if ($code -ne 0) {
        $script:Failed.Add($Description)
        Write-Warning "Failed: $Description (exit $code)"
    } else {
        $script:Ok.Add($Description)
    }
}

function Invoke-Winget {
    param([string]$Description, [string[]]$Arguments)
    if ($WhatIfPreference) { Write-Host "would: winget $($Arguments -join ' ')"; return }
    Write-Host "==> winget $($Arguments -join ' ')"
    try {
        $output = & winget @Arguments 2>&1 | ForEach-Object { "$_" }
        $code = $LASTEXITCODE
    } catch {
        $script:Failed.Add($Description)
        Write-Warning "Failed: $Description - $($_.Exception.Message)"
        return
    }
    if ($code -eq 0) { $script:Ok.Add($Description); return }
    # winget returns an error when there is simply nothing to upgrade.
    if (($output -join "`n") -match 'No applicable upgrade|No available upgrade|No newer package|already installed|not installed') {
        Write-Host "OK: $Description (nothing to do)"
        $script:Ok.Add($Description)
        return
    }
    $script:Failed.Add($Description)
    Write-Warning "Failed: $Description (exit $code)"
    $output | Select-Object -Last 8 | ForEach-Object { Write-Host "  $_" }
}

function Test-Winget {
    param([string]$Id)
    $output = & winget list --id $Id -e --accept-source-agreements 2>&1 | ForEach-Object { "$_" }
    return [bool]($output -match [regex]::Escape($Id))
}

function Ensure-Winget {
    param([string]$Id, [string]$Name = $Id)
    if (Test-Winget $Id) {
        if ($InstallOnly) { Write-Host "OK: $Name (installed)"; return }
        Invoke-Winget "upgrade $Name" @(
            'upgrade', '--id', $Id, '-e', '--include-unknown',
            '--accept-source-agreements', '--accept-package-agreements',
            '--silent', '--disable-interactivity')
    } else {
        Invoke-Winget "install $Name" @(
            'install', '--id', $Id, '-e',
            '--accept-source-agreements', '--accept-package-agreements',
            '--silent', '--disable-interactivity')
    }
}

function Remove-Winget {
    param([string]$Id, [string]$Name = $Id)
    if (-not (Test-Winget $Id)) { return }
    if ($InstallOnly) {
        Write-Host "OK: $Name stays (install-only)"
        return
    }
    Invoke-Winget "uninstall $Name" @('uninstall', '--id', $Id, '-e', '--silent', '--disable-interactivity')
}

# winget updates the machine/user PATH, but this process keeps its old copy.
function Update-SessionPath {
    $machine = [Environment]::GetEnvironmentVariable('PATH', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('PATH', 'User')
    $parts = New-Object Collections.Generic.List[string]
    foreach ($entry in ((@($machine, $user, $env:PATH) -join ';').Split(';'))) {
        if (-not $entry -or $parts.Contains($entry)) { continue }
        $parts.Add($entry)
    }
    $env:PATH = $parts -join ';'
}

# Add a directory to the user PATH, keeping %VARIABLES% unexpanded.
function Add-UserPath {
    param([string]$Directory)
    $key = [Microsoft.Win32.Registry]::CurrentUser.OpenSubKey('Environment', $true)
    try {
        $raw = [string]$key.GetValue('Path', '', [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        $listed = $raw -split ';' | Where-Object { $_.Trim().TrimEnd('\') -ieq $Directory.TrimEnd('\') }
        if (-not $listed) {
            $kind = if ($key.GetValueNames() -contains 'Path') {
                $key.GetValueKind('Path')
            } else {
                [Microsoft.Win32.RegistryValueKind]::ExpandString
            }
            $value = if ($raw) { "$($raw.TrimEnd(';'));$Directory" } else { $Directory }
            $key.SetValue('Path', $value, $kind)
        }
    } finally {
        $key.Close()
    }
    if (($env:PATH -split ';') -notcontains $Directory) { $env:PATH = "$env:PATH;$Directory" }
}

function Get-MiseDataDir {
    if ($env:MISE_DATA_DIR) { return $env:MISE_DATA_DIR }
    return (Join-Path $env:LOCALAPPDATA 'mise')
}

# mise puts its shims here; the shell profile adds this too.
function Update-MisePath {
    $shims = Join-Path (Get-MiseDataDir) 'shims'
    if (Test-Path $shims) { Add-UserPath $shims }
}

function Ensure-MiseTool {
    param([string]$Tool, [string]$Command = $Tool)
    if ($InstallOnly -and (Get-Command $Command -ErrorAction SilentlyContinue)) {
        Write-Host "OK: $Tool (installed)"
        return
    }
    Invoke-Native "mise use -g $Tool@latest" 'mise' @('use', '-g', "$Tool@latest")
}

function Get-LatestReleaseAsset {
    param([string]$Repository, [string]$Pattern)
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repository/releases/latest" -Headers @{ 'User-Agent' = 'dotfiles-install-software' }
    $asset = $release.assets | Where-Object { $_.name -like $Pattern } | Select-Object -First 1
    if (-not $asset) { throw "no release asset matched '$Pattern' in $Repository $($release.tag_name)" }
    return $asset
}

# winget only ships PowerShell 7 as an MSIX bundle now, and the latest
# releases have no MSI (7.7 dropped it). An MSIX install lands in
# C:\Program Files\WindowsApps and puts a 0-byte App Execution Alias on PATH,
# which is not a PE image, so tools that look for a real pwsh.exe (herdr's
# pane shell detection) fall back to powershell.exe. Expose the real package
# directory through a stable junction instead. Re-run to repoint it after a
# Store update.
function Ensure-Pwsh {
    $link = Join-Path $env:LOCALAPPDATA 'Programs\PowerShell\7'
    $msi = Join-Path $env:ProgramFiles 'PowerShell\7\pwsh.exe'

    if (Test-Path $msi) {
        Write-Host 'OK: PowerShell 7 (MSI install)'
        Invoke-Action "add $(Split-Path $msi) to PATH" { Add-UserPath (Split-Path $msi) }
        return
    }

    $package = Get-ChildItem (Join-Path $env:ProgramFiles 'WindowsApps') -Directory `
        -Filter 'Microsoft.PowerShell_*_x64__8wekyb3d8bbwe' -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName 'pwsh.exe') } |
        Sort-Object { try { [version](($_.Name -split '_')[1]) } catch { [version]'0.0.0.0' } } |
        Select-Object -Last 1
    if (-not $package) {
        Write-Warning 'PowerShell 7 was not found. Install it from https://aka.ms/powershell-release?tag=stable, then re-run this script.'
        return
    }

    $current = Get-Item $link -ErrorAction SilentlyContinue
    if ($current -and $current.LinkType -eq 'Junction' -and
        @($current.Target) -contains $package.FullName -and
        (Test-Path (Join-Path $link 'pwsh.exe'))) {
        Write-Host 'OK: PowerShell 7 (installed)'
        Invoke-Action "add $link to PATH" { Add-UserPath $link }
        return
    }

    Invoke-Action "link PowerShell 7 into $link" {
        New-Item -ItemType Directory -Force (Split-Path $link) | Out-Null
        # Directory.Delete drops the junction itself, never the package it points at.
        if ([IO.Directory]::Exists($link)) { [IO.Directory]::Delete($link) }
        New-Item -ItemType Junction -Path $link -Target $package.FullName | Out-Null
        Add-UserPath $link
    }
}

function Ensure-Tuicr {
    $destination = Join-Path $env:LOCALAPPDATA 'Programs\tuicr'
    if ((Test-Path (Join-Path $destination 'tuicr.exe')) -and $InstallOnly) {
        Write-Host 'OK: tuicr (installed)'
        return
    }
    Invoke-Action 'install/update tuicr' {
        $asset = Get-LatestReleaseAsset -Repository 'agavra/tuicr' -Pattern '*x86_64-pc-windows-msvc.zip'
        $tmp = Join-Path ([IO.Path]::GetTempPath()) "tuicr-$PID"
        New-Item -ItemType Directory -Force $tmp | Out-Null
        try {
            $archive = Join-Path $tmp 'tuicr.zip'
            Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $archive -UseBasicParsing
            Expand-Archive -Path $archive -DestinationPath $tmp -Force
            $found = Get-ChildItem -Path $tmp -Recurse -Filter 'tuicr.exe' | Select-Object -First 1
            if (-not $found) { throw 'tuicr.exe was not in the archive' }
            New-Item -ItemType Directory -Force $destination | Out-Null
            Copy-Item -LiteralPath $found.FullName -Destination (Join-Path $destination 'tuicr.exe') -Force
        } finally {
            Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
        }
        Add-UserPath $destination
    }
}

function Install-NerdFont {
    param([string]$Family = 'FiraCode')
    $registryPath = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'
    $fontDirectory = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'

    $already = @()
    if (Test-Path $registryPath) {
        $properties = Get-ItemProperty -Path $registryPath -ErrorAction SilentlyContinue
        if ($properties) {
            $already = @($properties.PSObject.Properties | Where-Object { $_.Name -like "*$Family*Nerd*" })
        }
    }
    if ($already) {
        Write-Host "OK: $Family Nerd Font (installed)"
        return
    }

    Invoke-Action "install $Family Nerd Font" {
        $url = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$Family.zip"
        $tmp = Join-Path ([IO.Path]::GetTempPath()) "nerdfont-$PID"
        New-Item -ItemType Directory -Force $tmp | Out-Null
        try {
            $archive = Join-Path $tmp 'font.zip'
            Invoke-WebRequest -Uri $url -OutFile $archive -UseBasicParsing
            Expand-Archive -Path $archive -DestinationPath $tmp -Force
            $fonts = @(Get-ChildItem -Path $tmp -Recurse -Filter '*.ttf')
            if ($fonts.Count -eq 0) { throw 'no .ttf files were in the archive' }

            New-Item -ItemType Directory -Force $fontDirectory | Out-Null
            if (-not (Test-Path $registryPath)) { New-Item -Path $registryPath -Force | Out-Null }
            foreach ($font in $fonts) {
                $installed = Join-Path $fontDirectory $font.Name
                Copy-Item -LiteralPath $font.FullName -Destination $installed -Force
                New-ItemProperty -Path $registryPath -Name "$($font.BaseName) (TrueType)" `
                    -Value $installed -PropertyType String -Force | Out-Null
            }

            # Make the fonts usable by programs started from this session.
            if (-not ('DotfilesFontApi' -as [type])) {
                Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class DotfilesFontApi {
    [DllImport("gdi32.dll", CharSet = CharSet.Unicode)]
    public static extern int AddFontResource(string lpFileName);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern IntPtr SendMessage(IntPtr hWnd, int msg, IntPtr wParam, IntPtr lParam);
}
'@
            }
            foreach ($font in $fonts) {
                [void][DotfilesFontApi]::AddFontResource((Join-Path $fontDirectory $font.Name))
            }
            [void][DotfilesFontApi]::SendMessage([IntPtr]0xffff, 0x001D, [IntPtr]::Zero, [IntPtr]::Zero)
        } finally {
            Remove-Item -Recurse -Force $tmp -ErrorAction SilentlyContinue
        }
    }
}

function Install-Skills {
    if (-not (Get-Command npx -ErrorAction SilentlyContinue)) {
        Write-Warning 'npx was not found; skipping the agent skills.'
        return
    }
    # The trailing -y (or --force) is for the tool; npx's -y only skips its own prompt.
    Invoke-Native 'skill ui-ux-pro-max' 'npx' @('-y', 'ui-ux-pro-max-cli', 'init', '--ai', 'universal', '--global', '--force')
    Invoke-Native 'skill impeccable' 'npx' @('-y', 'impeccable', 'install', '--scope=global', '-y')
    Invoke-Native 'skill mattpocock/skills' 'npx' @('-y', 'skills', 'add', 'mattpocock/skills', '-g', '-y')
    Invoke-Native 'skill addyosmani/agent-skills' 'npx' @('-y', 'skills', 'add', 'addyosmani/agent-skills', '-g', '-y')
    Invoke-Native 'skill plannotator-tui' 'npx' @('-y', 'skills', 'add', 'plannotator/herdr-annotate', '--skill', 'plannotator-tui', '-g', '-y')
    Write-Host 'awesome-design-md has no installer; copy a DESIGN.md from'
    Write-Host 'https://github.com/VoltAgent/awesome-design-md when you want one.'
}

$core = @(
    @{ Id = 'Git.Git'; Name = 'Git' },
    @{ Id = 'Neovim.Neovim'; Name = 'Neovim' },
    @{ Id = 'Starship.Starship'; Name = 'starship' },
    @{ Id = 'sharkdp.fd'; Name = 'fd' },
    @{ Id = 'junegunn.fzf'; Name = 'fzf' },
    @{ Id = 'BurntSushi.ripgrep.MSVC'; Name = 'ripgrep' },
    @{ Id = 'sharkdp.bat'; Name = 'bat' },
    @{ Id = 'eza-community.eza'; Name = 'eza' },
    @{ Id = 'ajeetdsouza.zoxide'; Name = 'zoxide' },
    @{ Id = 'JesseDuffield.lazygit'; Name = 'lazygit' },
    @{ Id = 'dandavison.delta'; Name = 'delta' },
    @{ Id = 'jqlang.jq'; Name = 'jq' },
    @{ Id = 'wez.wezterm'; Name = 'WezTerm' },
    @{ Id = 'jdx.mise'; Name = 'mise' }
)

$optional = @(
    @{ Id = 'pnpm.pnpm'; Name = 'pnpm' }
)

Write-Host '== Core tools (winget) =='
foreach ($package in $core) { Ensure-Winget -Id $package.Id -Name $package.Name }

if ($SkipOptional) {
    Write-Host '== Optional tools (winget) == (skipped)'
} else {
    Write-Host '== Optional tools (winget) =='
    foreach ($package in $optional) { Ensure-Winget -Id $package.Id -Name $package.Name }
}

Update-SessionPath

Write-Host '== Remove old winget copies =='
Remove-Winget 'OpenJS.NodeJS.LTS' 'Node.js (winget)'
Remove-Winget 'Python.Python.3.13' 'Python 3.13 (winget)'
Remove-Winget 'Schniz.fnm' 'fnm (winget)'
if (-not $SkipOptional) {
    Remove-Winget 'Rustlang.Rustup' 'Rustup (winget)'
}

Update-SessionPath
Update-MisePath

Write-Host '== mise tools =='
if (Get-Command mise -ErrorAction SilentlyContinue) {
    Ensure-MiseTool 'node' 'node'
    Ensure-MiseTool 'python' 'python'
    Ensure-MiseTool 'herdr'
    Ensure-MiseTool 'tuios'
    Ensure-MiseTool 'opencode'
    Ensure-MiseTool 'tree-sitter'
    Ensure-MiseTool 'rtk'
    if (-not $SkipOptional) {
        Ensure-MiseTool 'rust' 'rustc'
    }
    Update-MisePath
} else {
    Write-Warning 'mise was not found; skipping the mise-managed tools.'
}

Write-Host '== opencode plugins =='
if (Get-Command opencode -ErrorAction SilentlyContinue) {
    Invoke-Native 'opencode plugin opencode-mesh' 'opencode' @('plugin', 'add', 'opencode-mesh')
    if (-not $InstallOnly) {
        Invoke-Native 'opencode plugin update' 'opencode' @('plugin', 'update')
    }
} else {
    Write-Warning 'opencode was not found; skipping its plugins.'
}

Write-Host '== rtk init =='
if (Get-Command rtk -ErrorAction SilentlyContinue) {
    Invoke-Native 'rtk init -g --opencode' 'rtk' @('init', '-g', '--opencode')
} else {
    Write-Warning 'rtk was not found; skipping rtk init.'
}

Write-Host '== Hand-installed tools =='
Ensure-Pwsh
Ensure-Tuicr
Update-SessionPath

if ($SkipFont) {
    Write-Host '== Nerd Font == (skipped)'
} else {
    Write-Host '== Nerd Font =='
    Install-NerdFont
}

if ($SkipSkills) {
    Write-Host '== Agent skills == (skipped)'
} else {
    Write-Host '== Agent skills =='
    Install-Skills
}

if ($WithWsl) {
    Write-Host '== WSL =='
    if (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
        $linuxCommand = 'bash "$HOME/.dotfiles/bin/install-software"'
        if ($InstallOnly) { $linuxCommand += ' --install-only' }
        if ($SkipOptional) { $linuxCommand += ' --skip-optional' }
        if ($SkipSkills) { $linuxCommand += ' --skip-skills' }
        Invoke-Native 'run bin/install-software in WSL' 'wsl.exe' @('--', 'bash', '-lc', $linuxCommand)
    } else {
        Write-Warning 'WSL was not found; skipping the Linux script.'
    }
}

Write-Host ''
if ($WhatIfPreference) {
    Write-Host 'Dry run done; nothing was changed.'
    exit 0
}

Write-Host "Done: $($script:Ok.Count) succeeded, $($script:Failed.Count) failed."
if ($script:Failed.Count -gt 0) {
    $script:Failed | ForEach-Object { Write-Host "  failed: $_" }
    exit 1
}
