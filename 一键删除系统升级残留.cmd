@echo off
setlocal EnableExtensions
title One-click delete C:\$WINDOWS.~BT

rem ---- self-elevate to Administrator ----
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo Requesting administrator privileges... please click YES on the UAC window.
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "TARGET=C:\$WINDOWS.~BT"
set "LOG=%USERPROFILE%\Desktop\WindowsBT_delete_log.txt"

if not exist "%TARGET%" (
    echo.
    echo [OK] "%TARGET%" not found - already gone.
    echo OK-ALREADY-GONE %date% %time%>> "%LOG%"
    pause
    exit /b
)

echo.
echo Target to delete : %TARGET%
echo WARNING: this is PERMANENT and cannot be undone.
echo.
set /p "GO=Type Y and press Enter to DELETE (anything else cancels): "
if /i not "%GO%"=="Y" (
    echo Cancelled.
    pause
    exit /b
)

echo.
echo Stopping Windows Update services...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1

echo [1/2] Fast delete (rd /s /q)...
rd /s /q "%TARGET%" 2>nul

if exist "%TARGET%" (
    echo [2/2] Blocked by permissions - taking ownership, then retrying. This can take a while...
    takeown /f "%TARGET%" /r /d y >nul 2>&1
    icacls "%TARGET%" /grant Administrators:F /t /c >nul 2>&1
    rd /s /q "%TARGET%" 2>nul
)

net start wuauserv >nul 2>&1

if exist "%TARGET%" (
    echo.
    echo [FAILED] Still exists.
    echo Tip: close any Explorer window opened on it, or use  Win+R  then  cleanmgr  then Clean up system files.
    echo FAILED %date% %time%>> "%LOG%"
) else (
    echo.
    echo [DONE] Deleted %TARGET%.
    echo DONE %date% %time%>> "%LOG%"
)

powershell -NoProfile -Command "$d=Get-PSDrive C; Write-Host ('C: free = ' + [math]::Round($d.Free/1GB,2) + ' GB')"
pause
