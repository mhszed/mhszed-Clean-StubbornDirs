<#
.SYNOPSIS
    Clean-StubbornDirs - Force-remove locked / access-denied folders on Windows.

.DESCRIPTION
    For each target directory the script:
      1. takes ownership (takeown /r),
      2. grants the Administrators group full control (icacls /t),
      3. deletes the directory recursively (Remove-Item -Recurse -Force),
    and writes a per-target before/after size report to a log file.

    It is meant for leftovers such as $WINDOWS.~BT or folders owned by
    SYSTEM / TrustedInstaller that a normal "Delete" cannot remove even
    when run as Administrator.

    Supports -WhatIf (dry run) and refuses critical system paths unless
    -Force is supplied. Requires an elevated (Run as Administrator) shell
    for system-owned folders.

.PARAMETER Path
    One or more directory paths to delete. Accepts pipeline input.

.PARAMETER LogPath
    Log file path. Default: %USERPROFILE%\Clean-StubbornDirs.log

.PARAMETER StopUpdateService
    Stop wuauserv and bits before deleting, restart them afterwards.
    Useful for C:\Windows\SoftwareDistribution\Download.

.PARAMETER Force
    Allow protected paths (drive roots, C:\Windows, Program Files, ...).
    Dangerous - use with care.

.PARAMETER Yes
    Do not ask for confirmation (sets $ConfirmPreference = 'None').
    Useful for non-interactive launchers / -File invocation where
    '-Confirm:$false' does not bind properly.

.EXAMPLE
    .\Clean-StubbornDirs.ps1 -Path 'C:\$WINDOWS.~BT' -WhatIf

.EXAMPLE
    .\Clean-StubbornDirs.ps1 -Path 'C:\$WINDOWS.~BT' -Confirm:$false

.EXAMPLE
    .\Clean-StubbornDirs.ps1 -Path 'D:\Leftover1','D:\Leftover2' -StopUpdateService
#>
[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
    [string[]]$Path,

    [string]$LogPath = (Join-Path $env:USERPROFILE 'Clean-StubbornDirs.log'),

    [switch]$StopUpdateService,

    [switch]$Force,

    [switch]$Yes
)

begin {
    $ErrorActionPreference = 'SilentlyContinue'

    if ($Yes) { $ConfirmPreference = 'None' }

    $protected = @(
        'C:\',
        'C:\Windows',
        'C:\Windows\System32',
        'C:\Windows\SysWOW64',
        'C:\Program Files',
        'C:\Program Files (x86)',
        'C:\ProgramData',
        'C:\Users',
        $env:USERPROFILE
    ) | ForEach-Object { $_.TrimEnd('\').ToLower() }

    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    function Write-Log([string]$message) {
        $line = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $message
        Write-Host $line
        Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8 -WhatIf:$false -ErrorAction SilentlyContinue
    }

    function Get-DirSize([string]$p) {
        if (Test-Path -LiteralPath $p) {
            $sum = (Get-ChildItem -LiteralPath $p -Recurse -File -Force -ErrorAction SilentlyContinue |
                    Measure-Object Length -Sum).Sum
            if ($null -eq $sum) { return 0 }
            return $sum
        }
        return 0
    }

    if (-not $isAdmin) {
        Write-Warning 'Not running as Administrator. System-owned folders will fail. Re-open PowerShell with "Run as Administrator".'
    }

    Write-Log '=== Clean-StubbornDirs start ==='
    $script:totalFreed = 0
}

process {
    foreach ($target in $Path) {
        if ([string]::IsNullOrWhiteSpace($target)) { continue }

        $full = [System.IO.Path]::GetFullPath($target)
        $norm = $full.TrimEnd('\').ToLower()

        if (-not (Test-Path -LiteralPath $full)) {
            Write-Log ('SKIP (not found): {0}' -f $full)
            continue
        }

        $isProtected = ($protected -contains $norm) -or ($norm -match '^[a-z]:$')
        if ($isProtected -and -not $Force) {
            Write-Log ('REFUSED (protected path; use -Force to override): {0}' -f $full)
            continue
        }

        $before = Get-DirSize $full

        if (-not $PSCmdlet.ShouldProcess($full, 'Take ownership and delete recursively')) {
            Write-Log ('WHATIF: would delete {0} ({1} MB)' -f $full, [math]::Round($before / 1MB, 1))
            continue
        }

        if ($StopUpdateService) {
            Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
            Stop-Service bits -Force -ErrorAction SilentlyContinue
            Write-Log 'Stopped services: wuauserv, bits'
        }

        Write-Log ('Taking ownership: {0}' -f $full)
        & takeown /f $full /r /d y *> $null
        & icacls $full /grant 'Administrators:F' /t /c *> $null

        Write-Log ('Deleting: {0}' -f $full)
        Remove-Item -LiteralPath $full -Recurse -Force -ErrorAction SilentlyContinue

        $after = Get-DirSize $full
        $freed = $before - $after
        if ($freed -lt 0) { $freed = 0 }
        $script:totalFreed += $freed

        if (Test-Path -LiteralPath $full) {
            Write-Log ('PARTIAL/FAILED: {0}  before={1} MB  after={2} MB' -f $full, [math]::Round($before/1MB,1), [math]::Round($after/1MB,1))
        } else {
            Write-Log ('OK: {0}  freed={1} MB' -f $full, [math]::Round($before/1MB,1))
        }
    }
}

end {
    if ($StopUpdateService) {
        Start-Service wuauserv -ErrorAction SilentlyContinue
        Write-Log 'Restarted service: wuauserv'
    }
    Write-Log ('=== done. Total freed: {0} GB ===' -f [math]::Round($script:totalFreed / 1GB, 2))
}
