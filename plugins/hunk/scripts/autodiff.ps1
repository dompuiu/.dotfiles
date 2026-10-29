# Event hook for pane.agent_status_changed: when an agent goes idle with
# uncommitted changes, open a live hunk diff split beside its pane (unfocused).
# Opt out: create "$(herdr plugin config-dir hunk)/autodiff-off"
# Windows counterpart of autodiff.zsh.
$ErrorActionPreference = 'Continue'
$PSNativeCommandUseErrorActionPreference = $false

function Write-Skip($msg) { Write-Output "skip: $msg" }

. (Join-Path $PSScriptRoot 'lib.ps1')

$cfgDir = $env:HERDR_PLUGIN_CONFIG_DIR
if (-not $cfgDir) {
  $cfgDir = (& $herdrBin plugin config-dir hunk 2>$null | Select-Object -Last 1).Trim()
}
if ($cfgDir -and (Test-Path -LiteralPath (Join-Path $cfgDir 'autodiff-off')) ) {
  Write-Skip 'autodiff off'
  exit 0
}

$evtRaw = $env:HERDR_PLUGIN_EVENT_JSON
if (-not $evtRaw) { exit 0 }
try { $evt = $evtRaw | ConvertFrom-Json -ErrorAction Stop }
catch { exit 0 }

$status = $null; $paneId = $null
if ($evt.data) {
  $status = $evt.data.agent_status
  if (-not $status) { $status = $evt.data.agentStatus }
  $paneId = $evt.data.pane_id
  if (-not $paneId) { $paneId = $evt.data.paneId }
}
if (-not $status) { $status = $evt.agent_status }
if (-not $paneId) { $paneId = $evt.pane_id }
if (-not $status -or -not $paneId) { exit 0 }
if ($status -ne 'idle') { Write-Skip "status=$status"; exit 0 }

if (-not (Get-Command hunk -ErrorAction SilentlyContinue)) {
  Write-Skip 'no hunk on PATH'
  exit 0
}

$infoRaw = (& $herdrBin pane get $paneId 2>$null)
if ($LASTEXITCODE -ne 0 -or -not $infoRaw) { Write-Skip 'pane get failed'; exit 0 }
try { $info = ($infoRaw | ConvertFrom-Json -ErrorAction Stop) }
catch { Write-Skip 'pane get parse failed'; exit 0 }
$cwd = $info.result.pane.foreground_cwd
if (-not $cwd) { $cwd = $info.result.pane.cwd }
if (-not $cwd -or -not (Test-Path -LiteralPath $cwd -PathType Container)) {
  Write-Skip "bad cwd=$cwd"
  exit 0
}

$root = (git -C $cwd rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or -not $root) { Write-Skip "not git repo cwd=$cwd"; exit 0 }
$root = $root.Trim()
# git prints forward slashes; hunk sessions register native paths.
# Normalize so `hunk session get --repo` matches the live viewer.
try { $root = (Resolve-Path -LiteralPath $root -ErrorAction Stop).Path } catch {}

$porcelain = (git -C $root status --porcelain 2>$null)
if (-not $porcelain) { Write-Skip "no changes in $root"; exit 0 }

hunk session get --repo $root 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) { Write-Skip "session live for $root"; exit 0 }

# The hunk daemon may not track sessions on this platform; fall back to
# herdr's own pane list: a live `hunk diff --watch` viewer auto-reloads,
# so never stack a second one in the same tab.
try {
  $myTab = ($info.result.pane.tab_id)
  $allPanes = ((& $herdrBin pane list 2>$null) | ConvertFrom-Json -ErrorAction Stop).result.panes
  $existing = $allPanes | Where-Object { $_.label -eq 'hunk' -and $_.tab_id -eq $myTab } | Select-Object -First 1
  if ($existing) { Write-Skip "hunk pane $($existing.pane_id) already open"; exit 0 }
} catch {}

# Reopen only when the diff changed since we last opened a pane for it, so a
# manually closed hunk pane stays closed until the agent produces new changes.
# Hash tracked diff AND untracked file contents (git diff can't see untracked).
$diffText = (git -C $root diff HEAD 2>$null)
if (-not $diffText) { $diffText = (git -C $root diff 2>$null) }
$untrackedHashes = @()
$others = (git -C $root ls-files --others --exclude-standard 2>$null)
foreach ($f in $others) {
  if (-not $f) { continue }
  $full = Join-Path $root $f
  if (Test-Path -LiteralPath $full -PathType Leaf) {
    try { $untrackedHashes += (Get-FileHash -LiteralPath $full -Algorithm SHA256 -ErrorAction Stop).Hash }
    catch { $untrackedHashes += $f }
  }
}
$sigInput = ($porcelain -join "`n") + "`n" + ($diffText -join "`n") + "`n" + ($untrackedHashes -join "`n")
$bytes = [System.Text.Encoding]::UTF8.GetBytes($sigInput)
$sha = [System.Security.Cryptography.SHA256]::Create()
$sig = ([BitConverter]::ToString($sha.ComputeHash($bytes)) -replace '-', '').ToLower()

$stateDir = $env:HERDR_PLUGIN_STATE_DIR
if (-not $stateDir) { $stateDir = Join-Path $HOME '.cache/hunk' }
New-Item -ItemType Directory -Force -Path $stateDir 2>$null | Out-Null
$rootHashBytes = [System.Text.Encoding]::UTF8.GetBytes($root.ToLower())
$rootKey = ([BitConverter]::ToString($sha.ComputeHash($rootHashBytes)) -replace '-', '').ToLower()
$keyFile = Join-Path $stateDir "$rootKey.sig"
if ((Test-Path -LiteralPath $keyFile) -and ((Get-Content -LiteralPath $keyFile -Raw -ErrorAction SilentlyContinue).Trim() -eq $sig)) {
  Write-Skip 'same sig'
  exit 0
}
try { Set-Content -LiteralPath $keyFile -Value $sig -NoNewline -ErrorAction Stop } catch {}

Write-Output "OPENING beside $paneId in $root"
if ((Test-Tuios) -and (Invoke-TuiosSplitRight $paneId $root '--no-focus' 'hunk-diff.ps1')) { exit 0 }
& $herdrBin plugin pane open `
  --plugin hunk --entrypoint hunk-diff-win `
  --placement split --direction right --no-focus `
  --target-pane $paneId `
  --cwd $root
exit $LASTEXITCODE
