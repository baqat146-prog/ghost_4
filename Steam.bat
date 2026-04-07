@echo off
setlocal enabledelayedexpansion
title Steam Deep Cleaner
:: Установка зеленого цвета (A - ярко-зеленый)
color 0A

:: Проверка прав администратора
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo Требуются права администратора
    echo Запускаю от имени администратора...
    timeout /t 2 /nobreak >nul
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /B
)

echo Начало очистки Steam
echo.

echo 1. Поиск Steam
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
    echo Ошибка: Steam не найден
    pause
    exit /B 1
)

set "STEAM_PATH=!STEAM_PATH:"=!"
if "!STEAM_PATH:~-1!"=="\" set "STEAM_PATH=!STEAM_PATH:~0,-1!"

echo Steam найден по адресу: !STEAM_PATH!
echo.

echo 2. Закрытие программ Steam
tasklist /FI "IMAGENAME eq steam.exe" 2>NUL | find /I "steam.exe" >NUL
if "!ERRORLEVEL!"=="0" (
    echo Закрываю процессы...
    taskkill /f /im steam.exe /t >nul 2>&1
    taskkill /f /im steamwebhelper.exe /t >nul 2>&1
    taskkill /f /im GameOverlayUI.exe /t >nul 2>&1
    timeout /t 2 /nobreak >nul
) else (
    echo Steam уже закрыт
)
echo.

echo 3. Удаление временных папок
if exist "!STEAM_PATH!\logs" rd /s /q "!STEAM_PATH!\logs" 2>nul & echo Удалена папка logs
if exist "!STEAM_PATH!\config" rd /s /q "!STEAM_PATH!\config" 2>nul & echo Удалена папка config
if exist "!STEAM_PATH!\userdata" rd /s /q "!STEAM_PATH!\userdata" 2>nul & echo Удалена папка userdata
if exist "!STEAM_PATH!\appcache" rd /s /q "!STEAM_PATH!\appcache" 2>nul & echo Удалена папка appcache
if exist "!STEAM_PATH!\steamapps\downloading" rd /s /q "!STEAM_PATH!\steamapps\downloading" 2>nul & echo Удалена папка временных загрузок
echo.

echo 4. Очистка реестра
reg delete "HKCU\Software\Valve\Steam" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Valve\Steam" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs\.steam" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs\steam" /f >nul 2>&1
echo Данные в реестре очищены
echo.

echo 5. Удаление временных файлов системы
del /f /q "%TEMP%\steam*.*" >nul 2>&1
del /f /q "C:\Windows\Prefetch\STEAM*.pf" >nul 2>&1
echo Очистка кэша завершена
echo.

echo Очистка полностью завершена
echo При следующем запуске Steam создаст новые файлы
echo.
echo Нажмите любую клавишу для выхода
pause >nul
exit /B 0
