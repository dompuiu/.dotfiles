# Overlay pane: fzf over open workspaces, saved sessions and zoxide dirs,
# then focus the match or create a workspace for it. Esc closes the overlay
# and herdr restores the previous pane. Windows counterpart of picker.zsh.
. (Join-Path $PSScriptRoot 'lib.ps1')
Assert-Command @('fzf')

$e = [char]27
$cReset = "$e[0m"; $cDim = "$e[2m"; $cHerdr = "$e[1;35m"; $cZox = "$e[1;32m"; $cSes = "$e[1;33m"; $cTree = "$e[90m"
$iWs = [char]::ConvertFromUtf32(0xF018D); $iTree = '↳'; $iDir = [char]0xF07B; $iSes = [char]0xF02E

$workspaces = @(Get-Workspaces)
$current = ($workspaces | Where-Object Focused | Select-Object -First 1).Id
$openIds = @($workspaces | ForEach-Object Id)
$openLabels = @($workspaces | ForEach-Object Label)

$prev = Read-History | Where-Object { $_ -ne $current -and $openIds -contains $_ } | Select-Object -First 1

function Format-Home([string]$Path) {
  if ($Path -and $Path.StartsWith($HOME, [StringComparison]::OrdinalIgnoreCase)) { return '~' + $Path.Substring($HOME.Length) }
  return $Path
}

function Get-NormPath([string]$Path) {
  try { return [IO.Path]::GetFullPath($Path).TrimEnd('\', '/') } catch { return $Path }
}

function Format-Fit([string]$Text, [int]$Width) {
  if ($Text.Length -gt $Width) { $Text = $Text.Substring(0, $Width - 1) + '…' }
  return $Text.PadRight($Width)
}

function Get-StatusIcon([string]$Status) {
  switch ($Status) {
    { $_ -in 'idle', 'done' } { return "$e[32m✓$cReset" }
    'working' { return "$e[33m●$cReset" }
    'blocked' { return "$e[31m!$cReset" }
    default { return ' ' }
  }
}

$lines = [Collections.Generic.List[string]]::new()
function Add-Line($Kind, $Key, $Path, $Display) { $lines.Add("$Kind`t$Key`t$Path`t$Display") }

# Group linked worktrees right after their parent repo workspace.
$grouped = [Collections.Generic.List[object]]::new()
foreach ($w in $workspaces | Where-Object { -not $_.Linked }) {
  $grouped.Add($w)
  if ($w.Repo) { $workspaces | Where-Object { $_.Linked -and $_.Repo -eq $w.Repo } | ForEach-Object { $grouped.Add($_) } }
}
$workspaces | Where-Object { $grouped -notcontains $_ } | ForEach-Object { $grouped.Add($_) }

for ($k = 0; $k -lt $grouped.Count; $k++) {
  $w = $grouped[$k]
  if ($w.Linked) {
    $nextLinked = ($k + 1 -lt $grouped.Count) -and $grouped[$k + 1].Linked
    $branch = if ($nextLinked) { '├─' } else { '└─' }
    $icon = $iTree; $name = "$cTree$branch$cReset $(Format-Fit $w.Label 26)"
  } else {
    $icon = $iWs; $name = Format-Fit $w.Label 29
  }
  if ($w.Id -eq $current) { $name = "$e[1m$name$cReset" }
  Add-Line 'ws' $w.Id $w.Cwd "$(Get-StatusIcon $w.Status) $cHerdr$icon herdr $cReset  $name  $cDim$(Format-Home $w.Cwd)$cReset"
}

$sessions = @(Get-Sessions)
foreach ($s in $sessions) {
  if ($openLabels -contains $s.Name) { continue }
  Add-Line 'session' $s.Name $s.Path "  $cSes$iSes sesh  $cReset  $(Format-Fit $s.Name 29)  $cDim$(Format-Home $s.Path)$cReset"
}

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
  $seen = @($workspaces | Where-Object Cwd | ForEach-Object { Get-NormPath $_.Cwd })
  foreach ($dir in (& zoxide query -l 2>$null)) {
    if (-not $dir -or -not (Test-Path -LiteralPath $dir -PathType Container)) { continue }
    if ($seen -contains (Get-NormPath $dir)) { continue }
    Add-Line 'dir' $dir $dir "  $cZox$iDir zoxide$cReset  $(Format-Fit (Split-Path -Leaf $dir) 29)  $cDim$(Format-Home $dir)$cReset"
  }
}

if ($lines.Count -eq 0) { Write-Host 'nothing to pick'; Start-Sleep -Seconds 1; exit 0 }

$preview = if (Get-Command eza -ErrorAction SilentlyContinue) {
  'eza -la --color=always --icons --group-directories-first --time-style=relative {3}'
} else { 'pwsh -NoLogo -NoProfile -Command Get-ChildItem -Force -LiteralPath {3}' }

$footer = 'enter select · ctrl+j/k move · ctrl+/ preview · esc back'
if ($prev) { $footer += "   ${cHerdr}last:$cReset $(($workspaces | Where-Object Id -eq $prev).Label)" }

$choice = $lines | fzf --delimiter "`t" --with-nth 4 --ansi --no-sort --layout=reverse `
  --border=rounded --border-label " ${cHerdr}Sesh Picker$cReset " --border-label-pos=3 `
  --header "${cHerdr}herdr / sesh$cReset   $cDim$($workspaces.Count) workspaces$cReset" --header-border=bottom `
  --footer $footer --footer-border=top `
  --prompt 'Sesh> ' --pointer '▌' --marker '+' --gutter ' ' `
  --info=inline-right --ghost 'Filter workspaces' `
  --list-label " ${cHerdr}WORKSPACES$cReset " `
  --color 'prompt:magenta:bold,pointer:magenta,hl:yellow,hl+:yellow:bold,label:magenta,border:bright-black' `
  --bind 'ctrl-j:down,ctrl-k:up,ctrl-/:toggle-preview' `
  --preview $preview --preview-label ' PREVIEW ' --preview-window 'right,40%,border-left'
if ($LASTEXITCODE -ne 0 -or -not $choice) { exit 0 }

$kind, $key, $target, $null = $choice -split "`t", 4

function New-SeshWorkspace([string]$Dir, [string]$Label, [string]$Startup) {
  if (-not (Test-Path -LiteralPath $Dir -PathType Container)) { Show-Toast "no such directory: $Dir"; exit 1 }
  $out = & $script:HerdrBin workspace create --cwd $Dir --label $Label 2>&1 | Out-String
  if ($LASTEXITCODE -ne 0) { Show-Toast "create failed: $out"; exit 1 }
  try { $j = $out | ConvertFrom-Json -ErrorAction Stop } catch { Show-Toast 'create: bad response'; exit 1 }
  $paneId = $j.result.root_pane.pane_id
  if ($Startup -and $paneId) { & $script:HerdrBin pane run $paneId $Startup 2>$null | Out-Null }
  if ($j.result.workspace.workspace_id) { Set-WorkspaceFocus $j.result.workspace.workspace_id }
}

switch ($kind) {
  'ws' { Set-WorkspaceFocus $key }
  'dir' { New-SeshWorkspace $target (Split-Path -Leaf $target) '' }
  'session' {
    $s = $sessions | Where-Object Name -eq $key | Select-Object -First 1
    if ($s) { New-SeshWorkspace $s.Path $s.Name $s.Startup }
  }
}
