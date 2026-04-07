@echo off
setlocal enabledelayedexpansion
title Steam Deep Cleaner
:: Set green color (A - bright green)
color 0A

:: Check for administrator rights
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Administrator privileges required
    echo Restarting as administrator...
    timeout /t 2 /nobreak >nul
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /B
)

echo Starting Steam cleanup
echo.

echo 1. Searching for Steam
set "STEAM_PATH="

for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" /v "InstallPath" 2^>nul') do (
    set "STEAM_PATH=%%b"
)
if "!STEAM_PATH!"=="" (
    for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Valve\Steam" /v "InstallPath" 2^>nul') do (
        set "STEAM_PATH=%%b"
    )
)
if "!STEAM_PATH!"=="" (
    for /f "tokens=2*" %%a in ('reg query "HKCU\Software\Valve\Steam" /v "SteamPath" 2^>nul') do (
        set "STEAM_PATH=%%b"
    )
)

if "!STEAM_PATH!"=="" (
    if exist "C:\Program Files (x86)\Steam\steam.exe" set "STEAM_PATH=C:\Program Files (x86)\Steam"
    if exist "C:\Program Files\Steam\steam.exe" set "STEAM_PATH=C:\Program Files\Steam"
)

if "!STEAM_PATH!"=="" (
    echo Error: Steam not found
    pause
    exit /B 1
)

set "STEAM_PATH=!STEAM_PATH:"=!"
if "!STEAM_PATH:~-1!"=="\" set "STEAM_PATH=!STEAM_PATH:~0,-1!"

echo Steam found at: !STEAM_PATH!
echo.

echo 2. Closing Steam processes
tasklist /FI "IMAGENAME eq steam.exe" 2>NUL | find /I "steam.exe" >NUL
if "!ERRORLEVEL!"=="0" (
    echo Closing processes...
    taskkill /f /im steam.exe /t >nul 2>&1
    taskkill /f /im steamwebhelper.exe /t >nul 2>&1
    taskkill /f /im GameOverlayUI.exe /t >nul 2>&1
    timeout /t 2 /nobreak >nul
) else (
    echo Steam is already closed
)
echo.

echo 3. Deleting temporary folders
if exist "!STEAM_PATH!\logs" rd /s /q "!STEAM_PATH!\logs" 2>nul & echo Deleted logs folder
if exist "!STEAM_PATH!\config" rd /s /q "!STEAM_PATH!\config" 2>nul & echo Deleted config folder
if exist "!STEAM_PATH!\userdata" rd /s /q "!STEAM_PATH!\userdata" 2>nul & echo Deleted userdata folder
if exist "!STEAM_PATH!\appcache" rd /s /q "!STEAM_PATH!\appcache" 2>nul & echo Deleted appcache folder
if exist "!STEAM_PATH!\steamapps\downloading" rd /s /q "!STEAM_PATH!\steamapps\downloading" 2>nul & echo Deleted temporary downloads folder
echo.

echo 4. Cleaning registry
reg delete "HKCU\Software\Valve\Steam" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Valve\Steam" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs\.steam" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs\steam" /f >nul 2>&1
echo Registry cleaned
echo.

echo 5. Removing system temporary files
del /f /q "%TEMP%\steam*.*" >nul 2>&1
del /f /q "C:\Windows\Prefetch\STEAM*.pf" >nul 2>&1
echo Cache cleanup completed
echo.

echo Cleanup fully completed
echo Steam will recreate necessary files on next launch
echo.
echo Press any key to exit
pause >nul
exit /B 0
