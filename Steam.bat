@echo off
setlocal enabledelayedexpansion
title Steam Deep Cleaner v1.0
color 0B
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
if '%errorlevel%' NEQ '0' (
    echo.
    echo  [!] Требуются права администратора!
    echo  [>] Запрашиваю повышение прав...
    timeout /t 2 /nobreak >nul
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /B
)

=
::             НАЧАЛО РАБОТЫ

echo.
echo  [>] Начинаю глубокую очистку Steam...
echo.


::         ПОИСК ПУТИ К STEAM

echo  [1/5] Поиск расположения Steam...

set "STEAM_PATH="

:: Проверка HKLM\WOW6432Node (64-bit системы)
for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" /v "InstallPath" 2^>nul') do (
    set "STEAM_PATH=%%b"
)

:: Если не найден - проверка HKLM\Valve\Steam
if "!STEAM_PATH!"=="" (
    for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Valve\Steam" /v "InstallPath" 2^>nul') do (
        set "STEAM_PATH=%%b"
    )
)

:: Если не найден - проверка HKCU
if "!STEAM_PATH!"=="" (
    for /f "tokens=2*" %%a in ('reg query "HKCU\Software\Valve\Steam" /v "SteamPath" 2^>nul') do (
        set "STEAM_PATH=%%b"
    )
)

:: Если всё ещё не найден - поиск по стандартным путям
if "!STEAM_PATH!"=="" (
    if exist "C:\Program Files (x86)\Steam\steam.exe" set "STEAM_PATH=C:\Program Files (x86)\Steam"
    if exist "C:\Program Files\Steam\steam.exe" set "STEAM_PATH=C:\Program Files\Steam"
    if exist "D:\Program Files (x86)\Steam\steam.exe" set "STEAM_PATH=D:\Program Files (x86)\Steam"
    if exist "E:\Program Files (x86)\Steam\steam.exe" set "STEAM_PATH=E:\Program Files (x86)\Steam"
    if exist "!USERPROFILE!\Steam\steam.exe" set "STEAM_PATH=!USERPROFILE!\Steam"
)

:: Финальная проверка
if "!STEAM_PATH!"=="" (
    echo  [X] ОШИБКА: Не удалось найти Steam!
    echo  [!] Убедитесь, что Steam установлен.
    echo.
    pause
    exit /B 1
)

:: Убираем лишние слеши и кавычки
set "STEAM_PATH=!STEAM_PATH:"=!"
if "!STEAM_PATH:~-1!"=="\" set "STEAM_PATH=!STEAM_PATH:~0,-1!"

echo  [✓] Steam найден: !STEAM_PATH!
echo.


::         ЗАКРЫТИЕ ПРОЦЕССОВ

echo  [2/5] Проверка и закрытие процессов Steam...

tasklist /FI "IMAGENAME eq steam.exe" 2>NUL | find /I "steam.exe" >NUL
if "!ERRORLEVEL!"=="0" (
    echo  [!] Steam запущен. Принудительно закрываю...
    taskkill /f /im steam.exe /t >nul 2>&1
    taskkill /f /im steamwebhelper.exe /t >nul 2>&1
    taskkill /f /im GameOverlayUI.exe /t >nul 2>&1
    timeout /t 3 /nobreak >nul
    echo  [✓] Процессы Steam завершены.
) else (
    echo  [✓] Steam не запущен.
)
echo.


::       УДАЛЕНИЕ ПАПОК

echo  [3/5] Удаление указанных папок...

:: Папка logs
if exist "!STEAM_PATH!\logs" (
    echo  [>] Удаляю: !STEAM_PATH!\logs
    rd /s /q "!STEAM_PATH!\logs" 2>nul
    if !ERRORLEVEL! EQU 0 (
        echo      [✓] Папка logs удалена.
    ) else (
        echo      [X] Ошибка при удалении logs (возможно, файл занят).
    )
) else (
    echo      [i] Папка logs не найдена.
)

:: Папка config
if exist "!STEAM_PATH!\config" (
    echo  [>] Удаляю: !STEAM_PATH!\config
    rd /s /q "!STEAM_PATH!\config" 2>nul
    if !ERRORLEVEL! EQU 0 (
        echo      [✓] Папка config удалена.
    ) else (
        echo      [X] Ошибка при удалении config (возможно, файл занят).
    )
) else (
    echo      [i] Папка config не найдена.
)

:: Папка userdata
if exist "!STEAM_PATH!\userdata" (
    echo  [>] Удаляю: !STEAM_PATH!\userdata
    rd /s /q "!STEAM_PATH!\userdata" 2>nul
    if !ERRORLEVEL! EQU 0 (
        echo      [✓] Папка userdata удалена.
    ) else (
        echo      [X] Ошибка при удалении userdata (возможно, файл занят).
    )
) else (
    echo      [i] Папка userdata не найдена.
)

:: Дополнительно: папка appcache (кэш HTTP)
if exist "!STEAM_PATH!\appcache" (
    echo  [>] Удаляю: !STEAM_PATH!\appcache (доп. кэш)
    rd /s /q "!STEAM_PATH!\appcache" 2>nul
)

:: Дополнительно: временные файлы загрузок
if exist "!STEAM_PATH!\steamapps\downloading" (
    echo  [>] Удаляю: !STEAM_PATH!\steamapps\downloading (временные загрузки)
    rd /s /q "!STEAM_PATH!\steamapps\downloading" 2>nul
)

echo.


::        ОЧИСТКА РЕЕСТРА

echo  [4/5] Удаление следов Steam в реестре...

:: Удаление ключей Steam из реестра
reg delete "HKCU\Software\Valve\Steam" /f >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    echo      [✓] Удалён: HKCU\Software\Valve\Steam
) else (
    echo      [i] Ключ HKCU\Software\Valve\Steam не найден.
)

reg delete "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" /f >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    echo      [✓] Удалён: HKLM\SOFTWARE\WOW6432Node\Valve\Steam
) else (
    echo      [i] Ключ HKLM\SOFTWARE\WOW6432Node\Valve\Steam не найден.
)

reg delete "HKLM\SOFTWARE\Valve\Steam" /f >nul 2>&1
if !ERRORLEVEL! EQU 0 (
    echo      [✓] Удалён: HKLM\SOFTWARE\Valve\Steam
) else (
    echo      [i] Ключ HKLM\SOFTWARE\Valve\Steam не найден.
)

:: Очистка MRU (списка недавних файлов)
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs\.steam" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs\steam" /f >nul 2>&1

echo.


::         ФИНАЛЬНАЯ ОЧИСТКА

echo  [5/5] Финальная очистка системы...

:: Очистка временных файлов, связанных со Steam
del /f /q "%TEMP%\steam*.*" >nul 2>&1
del /f /q "%TEMP%\Steam_*.*" >nul 2>&1

:: Очистка Prefetch
del /f /q "C:\Windows\Prefetch\STEAM*.pf" >nul 2>&1

echo      [✓] Временные файлы удалены.
echo.

::              ЗАВЕРШЕНИЕ
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║                   ОЧИСТКА ЗАВЕРШЕНА!                     ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.
echo  [+] Удалены следующие папки:
echo      - !STEAM_PATH!\logs
echo      - !STEAM_PATH!\config
echo      - !STEAM_PATH!\userdata
echo.
echo  [+] Очищены разделы реестра:
echo      - HKCU\Software\Valve\Steam
echo      - HKLM\SOFTWARE\WOW6432Node\Valve\Steam
echo      - HKLM\SOFTWARE\Valve\Steam
echo.
echo  [i] При следующем запуске Steam создаст новые чистые файлы.
echo.
echo  Нажмите любую клавишу для выхода...
pause >nul
exit /B 0
