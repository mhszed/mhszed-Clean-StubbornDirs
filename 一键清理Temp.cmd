@echo off
setlocal EnableExtensions
title One-click clean Temp files

rem ---- self-elevate to Administrator (needed for C:\Windows\Temp) ----
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo Requesting administrator privileges... please click YES on the UAC window.
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "PS1=%~dp0Clear-TempDirs.ps1"
if not exist "%PS1%" (
    echo.
    echo Clear-TempDirs.ps1 not found next to this launcher.
    pause
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
echo.
echo Log: %USERPROFILE%\Desktop\TempClean_log.txt
pause
