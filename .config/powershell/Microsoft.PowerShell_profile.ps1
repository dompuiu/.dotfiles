# PowerShell profile. On macOS/Linux pwsh loads this file from ~/.config/powershell
# directly; on Windows, install.ps1 adds a line to $PROFILE that dot-sources it.

$env:EDITOR = 'nvim'
if ($IsWindows) { $env:TERM = 'xterm-256color' }

# Run a tool's init command once and cache the script, regenerating it only
# when the binary is newer than the cache. Starting programs is slow on
# Windows, so this saves a process launch per tool on every shell. Returns the
# script path; dot-source it at the top level so its functions stay defined.
function Get-CachedInit {
    param([string]$Name, [scriptblock]$Generate)
    $cmd = Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $cmd) { return }
    $cacheDir = Join-Path ($env:XDG_CACHE_HOME ?? (Join-Path $HOME '.cache')) 'powershell'
    $file = Join-Path $cacheDir "init-$Name.ps1"
    $cache = Get-Item -LiteralPath $file -ErrorAction SilentlyContinue
    if (-not $cache -or $cache.Length -eq 0 -or (Get-Item -LiteralPath $cmd.Source).LastWriteTime -gt $cache.LastWriteTime) {
        New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
        & $Generate | Out-String | Set-Content -LiteralPath $file -Encoding utf8
    }
    return $file
}

# mise in shims mode, like zsh: tool versions resolve through the shims, with
# no per-prompt hook and no mise process at startup.
if (Get-Command mise -CommandType Application -ErrorAction SilentlyContinue) {
    $miseData = $env:MISE_DATA_DIR ?? $(if ($IsWindows) { Join-Path $env:LOCALAPPDATA 'mise' } else { Join-Path ($env:XDG_DATA_HOME ?? (Join-Path $HOME '.local/share')) 'mise' })
    $miseShims = Join-Path $miseData 'shims'
    $sep = [IO.Path]::PathSeparator
    if (($env:PATH -split $sep) -notcontains $miseShims) { $env:PATH = "$miseShims$sep$env:PATH" }
    Remove-Variable miseData, miseShims, sep
}

if ($init = Get-CachedInit starship { starship init powershell --print-full-init }) { . $init }
if ($init = Get-CachedInit zoxide { zoxide init powershell --cmd cd }) { . $init }
if ($init = Get-CachedInit tuios { tuios completion powershell }) { . $init }
Remove-Variable init -ErrorAction SilentlyContinue

function pwsh-startup {
    $env:PWSH_STARTUP_TIME = 1
    try { & (Get-Process -Id $PID).Path -NoLogo -Command exit }
    finally { Remove-Item Env:PWSH_STARTUP_TIME }
}

# Keep this block last. Record how long this shell took to load, measured from
# process start so it includes the runtime itself. It stays silent unless asked:
# `$env:PWSH_STARTUP_TIME = 1; pwsh` prints it, `pwsh-startup` measures a fresh shell.
$global:PwshStartupMs = [int]((Get-Date) - (Get-Process -Id $PID).StartTime).TotalMilliseconds
if ($env:PWSH_STARTUP_TIME -and $env:PWSH_STARTUP_TIME -ne '0') {
    Write-Host "pwsh startup: $global:PwshStartupMs ms" -ForegroundColor DarkGray
}
