@echo off
setlocal EnableExtensions

rem ---- self-elevate to Administrator if needed ----
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo Requesting administrator privileges... please click YES on the UAC prompt.
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "SCRIPT=%~dp0Clean-StubbornDirs.ps1"
set "TARGET=%~1"

if "%TARGET%"=="" (
    echo.
    echo Type or paste the full folder path, then press Enter.
    set /p "TARGET=Path: "
)
set "TARGET=%TARGET:"=%"

if "%TARGET%"=="" (
    echo No path given. Bye.
    pause
    exit /b
)

echo.
echo ===== DRY RUN (nothing will be deleted) =====
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%SCRIPT%' -Path '%TARGET%' -WhatIf -Yes"
echo.
set /p "GO=Type Y and press Enter to DELETE for real (anything else cancels): "
if /i not "%GO%"=="Y" (
    echo Cancelled.
    pause
    exit /b
)

echo.
echo ===== DELETING =====
powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%SCRIPT%' -Path '%TARGET%' -Yes"
echo.
echo Done. Log file: %USERPROFILE%\Clean-StubbornDirs.log
pause
