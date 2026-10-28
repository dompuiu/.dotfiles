# Runs INSIDE the herdr pane (has a TTY, cwd = invoking pane's project).
# Equivalent of herdr-hunk scripts/picker.sh "Working tree (live)" path,
# without fzf: just become a live hunk watcher. Quitting hunk closes the pane.
# Native tools (git/hunk) legitimately exit non-zero (no session, clean repo).
# Like bash `set -uo pipefail` (no -e): keep going, check $LASTEXITCODE explicitly.
$ErrorActionPreference = 'Continue'
$PSNativeCommandUseErrorActionPreference = $false

$themeArgs = @()
if ($env:HUNK_THEME) { $themeArgs = @('--theme', $env:HUNK_THEME) }

if (-not (Get-Command hunk -ErrorAction SilentlyContinue)) {
  Write-Host 'hunk not found on PATH (npm i -g hunkdiff)'
  Read-Host 'press Enter to close'
  exit 1
}

$repoRoot = (git rev-parse --show-toplevel 2>$null)
if ($LASTEXITCODE -ne 0 -or -not $repoRoot) {
  Write-Host "not a git repository: $PWD"
  Read-Host 'press Enter to close'
  exit 1
}
$repoRoot = $repoRoot.Trim()
# git prints forward slashes; hunk sessions register native paths.
# Normalize so `hunk session get --repo` matches the live viewer.
try { $repoRoot = (Resolve-Path -LiteralPath $repoRoot -ErrorAction Stop).Path } catch {}

# Session-aware: if a hunk viewer is already open for this repo, reload it
# instead of stacking a second one; else become hunk.
hunk session get --repo $repoRoot 2>$null | Out-Null
if ($LASTEXITCODE -eq 0) {
  hunk session reload --repo $repoRoot -- diff 2>$null | Out-Null
  if ($LASTEXITCODE -eq 0) { exit 0 }
}

& hunk diff --watch @themeArgs
exit $LASTEXITCODE
