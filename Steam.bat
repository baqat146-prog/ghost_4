@echo off
chcp 65001 >nul
title Steam Cleaner
color 0A

echo ============================================
echo         ОЧИСТКА STEAM
echo ============================================
echo.

set "STEAM_PATH="

for %%P in (
    "C:\Program Files (x86)\Steam"
    "C:\Program Files\Steam"
    "D:\Steam"
    "D:\Program Files (x86)\Steam"
    "E:\Steam"
) do (
    if exist "%%~P\steam.exe" (
        set "STEAM_PATH=%%~P"
        goto :found
    )
)

for %%R in (
    "HKLM\SOFTWARE\WOW6432Node\Valve\Steam"
    "HKLM\SOFTWARE\Valve\Steam"
    "HKCU\SOFTWARE\Valve\Steam"
) do (
    for /f "tokens=2*" %%A in ('reg query "%%~R" /v InstallPath 2^>nul') do (
        if exist "%%B\steam.exe" (
            set "STEAM_PATH=%%B"
            goto :found
        )
    )
)

echo [!] Steam не найден автоматически.
set /p STEAM_PATH="Введите путь к Steam (например C:\Games\Steam): "

if not exist "%STEAM_PATH%\steam.exe" (
    echo [X] Неверный путь. Выход.
    pause
    exit /b 1
)

:found
echo [OK] Steam найден: %STEAM_PATH%
echo.

echo [1/5] Завершение процессов Steam...
taskkill /f /im steam.exe          >nul 2>&1
taskkill /f /im steamwebhelper.exe >nul 2>&1
taskkill /f /im GameOverlayUI.exe  >nul 2>&1
taskkill /f /im steamservice.exe   >nul 2>&1
timeout /t 3 /nobreak >nul
echo      Готово.
echo.

echo [2/5] Удаление папки logs...
if exist "%STEAM_PATH%\logs" (
    rd /s /q "%STEAM_PATH%\logs"
    echo      Удалено: %STEAM_PATH%\logs
) else (
    echo      Папка logs не найдена.
)
echo.

echo [3/5] Удаление папки config...
if exist "%STEAM_PATH%\config" (
    rd /s /q "%STEAM_PATH%\config"
    echo      Удалено: %STEAM_PATH%\config
) else (
    echo      Папка config не найдена.
)
echo.

echo [4/5] Удаление папки userdata...
if exist "%STEAM_PATH%\userdata" (
    rd /s /q "%STEAM_PATH%\userdata"
    echo      Удалено: %STEAM_PATH%\userdata
) else (
    echo      Папка userdata не найдена.
)
echo.

echo [5/5] Очистка следов в реестре...
reg delete "HKCU\SOFTWARE\Valve\Steam\Apps"               /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Valve\Steam\ActiveProcess"      /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Valve\Steam\StartupMode"        /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Valve\Steam\AlreadyReportedBug" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Valve\Steam"                    /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Valve\Steam"        /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Valve\Steam"                    /f >nul 2>&1
del /f /q "%APPDATA%\Microsoft\Windows\Recent\steam*.*"   >nul 2>&1
del /f /q "%APPDATA%\Microsoft\Windows\Recent\Steam*.*"   >nul 2>&1
del /f /q "%TEMP%\steam*.*"                               >nul 2>&1
del /f /q "%TEMP%\Steam*.*"                               >nul 2>&1
echo      Готово.
echo.

echo ============================================
echo   [OK] Очистка завершена!
echo        Удалены: logs, config, userdata
echo        Реестр очищен.
echo ============================================
echo.
pause
