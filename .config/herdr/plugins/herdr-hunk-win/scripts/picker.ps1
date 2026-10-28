# Runs INSIDE the herdr pane (has a TTY, cwd = the invoking pane's project).
# fzf menu -> hunk viewer. Quitting hunk closes the pane.
# Port of herdr-hunk scripts/picker.sh for Windows (no awk/sed/shasum).
$ErrorActionPreference = 'Continue'
$PSNativeCommandUseErrorActionPreference = $false

$themeArgs = @()
if ($env:HUNK_THEME) { $themeArgs = @('--theme', $env:HUNK_THEME) }

function Stop-WithMessage([string]$msg) {
  Write-Host $msg
  Read-Host 'press Enter to close' | Out-Null
  exit 1
}

function Remove-Ansi([string]$s) {
  return ($s -replace "$([char]27)\[[0-9;]*[A-Za-z]", '')
}

if (-not (Get-Command hunk -ErrorAction SilentlyContinue)) { Stop-WithMessage 'hunk not found on PATH (npm i -g hunkdiff)' }
if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) { Stop-WithMessage 'fzf not found on PATH (winget install fzf)' }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { Stop-WithMessage 'git not found on PATH' }

$repoRoot = (git rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or -not $repoRoot) { Stop-WithMessage "not a git repository: $PWD" }
$repoRoot = "$repoRoot".Trim()
try { $repoRoot = (Resolve-Path -LiteralPath $repoRoot -ErrorAction Stop).Path } catch {}

# Session-aware: if a hunk viewer is already open for this repo, reload it
# with the chosen view instead of opening a second one; else run hunk.
function Invoke-HunkView([string[]]$HunkArgs) {
  hunk session get --repo $repoRoot 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) {
    hunk session reload --repo $repoRoot -- @HunkArgs 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { exit 0 }
  }
  & hunk @HunkArgs @themeArgs
  exit $LASTEXITCODE
}

function Invoke-LogFzf([string[]]$ExtraArgs) {
  $sel = git log --oneline --color=always -200 | fzf --ansi --no-sort --reverse --height=100% @ExtraArgs `
    --preview 'git show --stat --color=always {1}' --preview-window=right,55%
  return $sel
}

$choice = @(
  'Working tree (live)'
  'Staged'
  'Last commit'
  'Pick commit'
  'Pick range (2 commits)'
  'Branch vs upstream'
  'Stash'
) | fzf --prompt='hunk> ' --reverse --height=100%
if (-not $choice) { exit 0 }
$choice = "$choice".Trim()

switch ($choice) {
  'Working tree (live)' {
    hunk session get --repo $repoRoot 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
      hunk session reload --repo $repoRoot -- diff 2>$null | Out-Null
      if ($LASTEXITCODE -eq 0) { exit 0 }
    }
    & hunk diff --watch @themeArgs
    exit $LASTEXITCODE
  }
  'Staged' {
    Invoke-HunkView @('diff', '--staged')
  }
  'Last commit' {
    Invoke-HunkView @('show')
  }
  'Pick commit' {
    $sel = Invoke-LogFzf @('--prompt', 'commit> ')
    if (-not $sel) { exit 0 }
    $sha = ((Remove-Ansi "$sel").Trim() -split '\s+')[0]
    if (-not $sha) { exit 0 }
    Invoke-HunkView @('show', $sha)
  }
  'Pick range (2 commits)' {
    $picks = git log --oneline --color=always -200 | fzf --ansi --no-sort --reverse --height=100% --multi 2 --prompt='range> ' `
      --header='TAB marks a commit (pick 2). Enter confirms. 1 marked = diff vs working tree.' `
      --preview 'git show --stat --color=always {1}' --preview-window=right,55%
    if (-not $picks) { exit 0 }
    $lines = @($picks | Where-Object { "$_".Trim() -ne '' })
    if ($lines.Count -eq 2) {
      # git log lists newest first; diff older..newer
      $newer = ((Remove-Ansi "$($lines[0])").Trim() -split '\s+')[0]
      $older = ((Remove-Ansi "$($lines[1])").Trim() -split '\s+')[0]
      Invoke-HunkView @('diff', "$older..$newer")
    } elseif ($lines.Count -eq 1) {
      $sha = ((Remove-Ansi "$($lines[0])").Trim() -split '\s+')[0]
      Invoke-HunkView @('diff', $sha)
    }
    exit 0
  }
  'Branch vs upstream' {
    $branch = (git branch --show-current 2>$null)
    if ($LASTEXITCODE -ne 0 -or -not $branch) { $branch = 'HEAD' }
    $branch = "$branch".Trim()
    $upstream = (git rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>$null)
    if ($LASTEXITCODE -ne 0 -or -not $upstream) {
      $upstream = ''
      foreach ($candidate in @('origin/main', 'origin/master', 'main', 'master')) {
        git rev-parse --verify -q $candidate 2>$null | Out-Null
        if ($LASTEXITCODE -eq 0) { $upstream = $candidate; break }
      }
    } else {
      $upstream = "$upstream".Trim()
    }
    if (-not $upstream) { Stop-WithMessage 'no upstream or base branch found' }
    Invoke-HunkView @('diff', "$upstream..$branch")
  }
  'Stash' {
    $sel = git stash list | fzf --prompt='stash> ' --reverse --height=100% --delimiter=: `
      --preview 'git stash show --stat --color=always {1}' --preview-window=right,55%
    if (-not $sel) { exit 0 }
    $ref = (("$sel" -split ':')[0]).Trim()
    if (-not $ref) { exit 0 }
    & hunk stash show $ref @themeArgs
    exit $LASTEXITCODE
  }
}
