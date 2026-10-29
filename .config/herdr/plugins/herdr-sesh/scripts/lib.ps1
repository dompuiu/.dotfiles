# Shared helpers for herdr-sesh pwsh scripts. Dot-source, don't execute.
$ErrorActionPreference = 'Continue'
$PSNativeCommandUseErrorActionPreference = $false

$script:HerdrBin = if ($env:HERDR_BIN_PATH) { $env:HERDR_BIN_PATH } else { 'herdr' }
$script:PluginId = if ($env:HERDR_PLUGIN_ID) { $env:HERDR_PLUGIN_ID } else { 'herdr-sesh' }

function Show-Toast([string]$Message) {
  & $script:HerdrBin notification show "herdr-sesh: $Message" --position top-right 2>$null | Out-Null
}

function Assert-Command([string[]]$Names) {
  foreach ($n in $Names) {
    if (-not (Get-Command $n -ErrorAction SilentlyContinue)) {
      Show-Toast "$n not found on PATH"
      [Console]::Error.WriteLine("missing: $n")
      exit 1
    }
  }
}

function Get-StateDir {
  $dir = $env:HERDR_PLUGIN_STATE_DIR
  if (-not $dir) { $dir = Join-Path $env:LOCALAPPDATA 'herdr-sesh' }
  New-Item -ItemType Directory -Force -Path $dir | Out-Null
  return $dir
}

function Get-ConfigDir {
  if ($env:HERDR_PLUGIN_CONFIG_DIR) { return $env:HERDR_PLUGIN_CONFIG_DIR }
  return (& $script:HerdrBin plugin config-dir $script:PluginId 2>$null | Select-Object -Last 1)
}

# One history file per herdr session; workspace ids are per-server.
function Get-HistoryFile {
  $session = if ($env:HERDR_SESSION) { $env:HERDR_SESSION } else { 'default' }
  return Join-Path (Get-StateDir) "history-$session"
}

function Read-History {
  $f = Get-HistoryFile
  if (Test-Path -LiteralPath $f) { return @(Get-Content -LiteralPath $f | Where-Object { $_ }) }
  return @()
}

# Returns objects with Id, Label, Focused, Cwd.
function Get-Workspaces {
  try { $ws = (& $script:HerdrBin workspace list 2>$null | Out-String | ConvertFrom-Json -ErrorAction Stop).result.workspaces }
  catch { return @() }
  try { $panes = @((& $script:HerdrBin pane list 2>$null | Out-String | ConvertFrom-Json -ErrorAction Stop).result.panes) }
  catch { $panes = @() }
  foreach ($w in $ws) {
    $cwd = $null
    if ($w.worktree -and $w.worktree.checkout_path) { $cwd = $w.worktree.checkout_path }
    if (-not $cwd) {
      $p = $panes | Where-Object { $_.workspace_id -eq $w.workspace_id } | Select-Object -First 1
      if ($p) { $cwd = $p.cwd }
    }
    $linked = [bool]($w.worktree -and $w.worktree.is_linked_worktree)
    $repo = if ($w.worktree) { "$($w.worktree.repo_root)" } else { '' }
    [pscustomobject]@{ Id = $w.workspace_id; Label = "$($w.label)"; Focused = [bool]$w.focused; Cwd = "$cwd"
      Status = "$($w.agent_status)"; Linked = $linked; Repo = $repo }
  }
}

function Set-WorkspaceFocus([string]$Id) {
  & $script:HerdrBin workspace focus $Id 2>$null | Out-Null
}

function Expand-SeshPath([string]$Path) {
  $p = $Path.Trim()
  if ($p -eq '~') { $p = $HOME }
  elseif ($p.StartsWith('~/') -or $p.StartsWith('~\')) { $p = Join-Path $HOME $p.Substring(2) }
  $p = [regex]::Replace($p, '\$(\w+)|\$\{(\w+)\}', {
    param($m)
    $name = if ($m.Groups[1].Success) { $m.Groups[1].Value } else { $m.Groups[2].Value }
    $v = [Environment]::GetEnvironmentVariable($name)
    if ($null -ne $v) { $v } else { $m.Value }
  })
  return [Environment]::ExpandEnvironmentVariables($p)
}

# Returns objects with Name, Path, Startup from "name | path | startup".
function Get-Sessions {
  $dir = Get-ConfigDir
  if (-not $dir) { return @() }
  $f = Join-Path $dir 'sessions'
  if (-not (Test-Path -LiteralPath $f)) { return @() }
  foreach ($raw in Get-Content -LiteralPath $f) {
    if ($raw -match '^\s*(#|$)') { continue }
    $parts = $raw -split '\|', 3
    $name = $parts[0].Trim()
    if (-not $name) { continue }
    [pscustomobject]@{
      Name    = $name
      Path    = if ($parts.Count -gt 1) { Expand-SeshPath $parts[1] } else { '' }
      Startup = if ($parts.Count -gt 2) { $parts[2].Trim() } else { '' }
    }
  }
}
