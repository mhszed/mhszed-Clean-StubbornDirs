# Clear-TempDirs.ps1
# Safely clean old junk files from Windows temp directories.
# Only deletes files older than N days (default 1), skips in-use files,
# never deletes the temp folders themselves. ASCII-only on purpose so it
# parses correctly in Windows PowerShell 5.1.

[CmdletBinding()]
param(
    [int]$Days = 1,
    [string[]]$Roots = @($env:TEMP, 'C:\Windows\Temp'),
    [string]$LogPath = (Join-Path $env:USERPROFILE 'Desktop\TempClean_log.txt'),
    [switch]$Yes
)

$ErrorActionPreference = 'SilentlyContinue'
$cutoff = (Get-Date).AddDays(-$Days)
$roots = @($Roots | Where-Object { $_ -and (Test-Path -LiteralPath $_) } | Select-Object -Unique)

if ($roots.Count -eq 0) { Write-Host 'No temp roots found.'; exit 0 }

function Get-OldFiles([string]$root) {
    Get-ChildItem -LiteralPath $root -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object { $_.LastWriteTime -lt $cutoff }
}

Write-Host "Scanning temp dirs (only files older than $Days day(s))..."
$plan = @()
$totalPlan = 0
foreach ($r in $roots) {
    $files = @(Get-OldFiles $r)
    $size = 0
    foreach ($f in $files) { $size += $f.Length }
    $plan += [PSCustomObject]@{ Root = $r; Files = $files; Size = $size }
    $totalPlan += $size
    Write-Host ("  {0,-55} {1,10:N1} MB  ({2} files)" -f $r, ($size / 1MB), $files.Count)
}
Write-Host ("Total that can be freed: {0:N2} GB" -f ($totalPlan / 1GB))

if ($totalPlan -le 0) { Write-Host 'Nothing to clean.'; exit 0 }

if (-not $Yes) {
    $go = Read-Host 'Type Y and press Enter to DELETE (anything else cancels)'
    if ($go -notin @('Y', 'y')) { Write-Host 'Cancelled.'; exit 0 }
}

$freed = 0
foreach ($p in $plan) {
    foreach ($f in $p.Files) {
        if (Test-Path -LiteralPath $f.FullName) {
            $len = $f.Length
            Remove-Item -LiteralPath $f.FullName -Force -ErrorAction SilentlyContinue
            if (-not (Test-Path -LiteralPath $f.FullName)) { $freed += $len }
        }
    }
}

# Remove now-empty subdirectories (never the root itself), deepest first.
foreach ($r in $roots) {
    $dirs = Get-ChildItem -LiteralPath $r -Recurse -Directory -Force -ErrorAction SilentlyContinue |
        Sort-Object { ($_.FullName -split '\\').Count } -Descending
    foreach ($d in $dirs) {
        if (-not (Get-ChildItem -LiteralPath $d.FullName -Force -ErrorAction SilentlyContinue)) {
            Remove-Item -LiteralPath $d.FullName -Force -ErrorAction SilentlyContinue
        }
    }
}

$msg = "[{0}] TempClean days={1} freed={2:N2} GB roots={3}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Days, ($freed / 1GB), ($roots -join ';')
Write-Host ("Freed: {0:N2} GB" -f ($freed / 1GB))
Add-Content -LiteralPath $LogPath -Value $msg -Encoding UTF8 -ErrorAction SilentlyContinue

$d = Get-PSDrive C
Write-Host ("C: free = {0:N2} GB" -f ($d.Free / 1GB))
