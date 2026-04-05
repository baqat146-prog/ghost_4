@echo off
chcp 65001 >nul
title Steam Cleaner
color 0A

echo ============================================
echo         ОЧИСТКА  STEAM
echo ============================================
echo.

:: ─── Поиск Steam ───────────────────────────────
set "STEAM_PATH="

:: Стандартные пути
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

:: Поиск через реестр
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

echo [!] Steam не найден в стандартных местах.
echo     Введите путь вручную (например: C:\Games\Steam)
echo.
set /p STEAM_PATH="Путь к Steam: "

if not exist "%STEAM_PATH%\steam.exe" (
    echo.
    echo [X] Неверный путь. Steam не найден.
    pause
    exit /b 1
)

:found
echo [OK] Steam найден: %STEAM_PATH%
echo.

:: ─── Завершение процессов Steam ────────────────
echo [1/5] Завершение процессов Steam...
taskkill /f /im steam.exe      >nul 2>&1
taskkill /f /im steamwebhelper.exe >nul 2>&1
taskkill /f /im GameOverlayUI.exe  >nul 2>&1
timeout /t 2 /nobreak >nul
echo      Готово.
echo.

:: ─── Очистка логов ─────────────────────────────
echo [2/5] Очистка папки logs...
if exist "%STEAM_PATH%\logs" (
    del /f /q "%STEAM_PATH%\logs\*.*" >nul 2>&1
    for /d %%D in ("%STEAM_PATH%\logs\*") do rd /s /q "%%D" >nul 2>&1
    echo      Готово.
) else (
    echo      Папка logs не найдена — пропускаем.
)
echo.

:: ─── Очистка config ────────────────────────────
echo [3/5] Очистка папки config...
if exist "%STEAM_PATH%\config" (
    :: Удаляем логи и кэши, но не loginusers.vdf и config.vdf
    del /f /q "%STEAM_PATH%\config\htmlcache\*.*" >nul 2>&1
    for /d %%D in ("%STEAM_PATH%\config\htmlcache\*") do rd /s /q "%%D" >nul 2>&1
    del /f /q "%STEAM_PATH%\config\coplay_*.vdf" >nul 2>&1
    echo      Готово.
) else (
    echo      Папка config не найдена — пропускаем.
)
echo.

:: ─── Очистка userdata ──────────────────────────
echo [4/5] Очистка папки userdata (кэш/логи)...
if exist "%STEAM_PATH%\userdata" (
    for /d %%U in ("%STEAM_PATH%\userdata\*") do (
        if exist "%%U\config\screenshots\thumbnails" (
            del /f /q "%%U\config\screenshots\thumbnails\*.*" >nul 2>&1
        )
        if exist "%%U\760\remote" (
            del /f /q "%%U\760\remote\*.*" >nul 2>&1
        )
    )
    echo      Готово.
) else (
    echo      Папка userdata не найдена — пропускаем.
)
echo.

:: ─── Очистка реестра ───────────────────────────
echo [5/5] Очистка следов в реестре...

:: Удаляем ключи недавних игр / активности
reg delete "HKCU\SOFTWARE\Valve\Steam\Apps" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Valve\Steam\ActiveProcess" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Valve\Steam\AlreadyReportedBug" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Valve\Steam\StartupMode" /f >nul 2>&1

:: Префетч и недавние файлы Windows
del /f /q "%APPDATA%\Microsoft\Windows\Recent\steam*.*" >nul 2>&1
del /f /q "%APPDATA%\Microsoft\Windows\Recent\Steam*.*" >nul 2>&1

:: Temp файлы Steam в системном TEMP
del /f /q "%TEMP%\steam*.*" >nul 2>&1

echo      Готово.
echo.
echo ============================================
echo   [✓] Очистка успешно завершена!
echo       Steam: %STEAM_PATH%
echo ============================================
echo.
pause