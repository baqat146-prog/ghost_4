@echo off
:: ============================================================
::  STEAM CLEANER - Автоматическая очистка следов Steam
::  Запуск от имени администратора обязателен
:: ============================================================

:: --- Автоподъём прав администратора ---
NET SESSION >nul 2>&1
IF %ERRORLEVEL% NEQ 0 (
    echo Запрос прав администратора...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    EXIT /B
)

:: --- Настройка консоли ---
chcp 65001 >nul
color 0A
title STEAM CLEANER - Запущен от имени Администратора

cls
echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║                ||||||     ||||||                         ║
echo  ║                                                          ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.

:: ============================================================
:: ШАГ 1: Поиск расположения Steam
:: ============================================================
echo  [*] Поиск установленного Steam...
echo.

SET "STEAM_PATH="

:: Поиск через реестр (основное место)
FOR /F "tokens=2*" %%A IN ('reg query "HKCU\SOFTWARE\Valve\Steam" /v "SteamPath" 2^>nul') DO (
    SET "STEAM_PATH=%%B"
)

:: Если не найдено - попробовать HKLM
IF NOT DEFINED STEAM_PATH (
    FOR /F "tokens=2*" %%A IN ('reg query "HKLM\SOFTWARE\Valve\Steam" /v "InstallPath" 2^>nul') DO (
        SET "STEAM_PATH=%%B"
    )
)

:: Если не найдено - попробовать WOW6432Node
IF NOT DEFINED STEAM_PATH (
    FOR /F "tokens=2*" %%A IN ('reg query "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" /v "InstallPath" 2^>nul') DO (
        SET "STEAM_PATH=%%B"
    )
)

:: Если реестр пустой - проверить стандартные пути
IF NOT DEFINED STEAM_PATH (
    IF EXIST "C:\Program Files (x86)\Steam\steam.exe" SET "STEAM_PATH=C:\Program Files (x86)\Steam"
)
IF NOT DEFINED STEAM_PATH (
    IF EXIST "C:\Program Files\Steam\steam.exe" SET "STEAM_PATH=C:\Program Files\Steam"
)
IF NOT DEFINED STEAM_PATH (
    IF EXIST "%LOCALAPPDATA%\Steam\steam.exe" SET "STEAM_PATH=%LOCALAPPDATA%\Steam"
)

:: Если всё ещё не найдено
IF NOT DEFINED STEAM_PATH (
    echo  [✗] Steam НЕ НАЙДЕН на этом компьютере!
    echo.
    echo  Возможно Steam не установлен или установлен в нестандартную папку.
    echo  Введите путь вручную (например: D:\Steam) или нажмите Enter для выхода:
    echo.
    SET /P "STEAM_PATH=  Путь: "
    IF NOT DEFINED STEAM_PATH GOTO :END_ERROR
    IF NOT EXIST "%STEAM_PATH%\steam.exe" (
        echo.
        echo  [✗] По указанному пути steam.exe не найден. Выход.
        GOTO :END_ERROR
    )
)

:: Нормализация слешей (реестр возвращает прямые слеши)
SET "STEAM_PATH=%STEAM_PATH:/=\%"

echo  [✓] Steam найден по пути:
echo      %STEAM_PATH%
echo.

:: ============================================================
:: ШАГ 2: Проверка и закрытие Steam
:: ============================================================
echo  [*] Проверка: запущен ли Steam...
tasklist /FI "IMAGENAME eq steam.exe" 2>nul | find /I "steam.exe" >nul
IF %ERRORLEVEL% EQU 0 (
    echo  [!] Steam запущен. Закрываем принудительно...
    taskkill /F /IM steam.exe >nul 2>&1
    taskkill /F /IM steamwebhelper.exe >nul 2>&1
    taskkill /F /IM steamservice.exe >nul 2>&1
    timeout /t 2 /nobreak >nul
    echo  [✓] Steam закрыт.
) ELSE (
    echo  [✓] Steam не запущен. Продолжаем.
)
echo.

:: ============================================================
:: ШАГ 3: Подтверждение от пользователя
:: ============================================================
echo  ┌─────────────────────────────────────────────────────────┐
echo  │  Будут удалены следующие папки:                         │
echo  │                                                         │
echo  │  • %STEAM_PATH%\logs
echo  │  • %STEAM_PATH%\config
echo  │  • %STEAM_PATH%\userdata
echo  │                                                         │
echo  │  А также ключи реестра Steam.                          │
echo  └─────────────────────────────────────────────────────────┘
echo.
SET /P "CONFIRM=  Продолжить? (Y/N): "
IF /I NOT "%CONFIRM%"=="Y" (
    echo.
    echo  [!] Операция отменена пользователем.
    GOTO :END_CANCEL
)
echo.

:: ============================================================
:: ШАГ 4: Удаление папки logs
:: ============================================================
echo  [*] Удаление папки LOGS...
IF EXIST "%STEAM_PATH%\logs" (
    RD /S /Q "%STEAM_PATH%\logs" >nul 2>&1
    IF EXIST "%STEAM_PATH%\logs" (
        echo  [✗] Не удалось удалить logs (файлы заняты?)
    ) ELSE (
        echo  [✓] logs — удалено успешно
    )
) ELSE (
    echo  [~] logs — папка не найдена (уже удалена или не существовала)
)

:: ============================================================
:: ШАГ 5: Удаление папки config
:: ============================================================
echo  [*] Удаление папки CONFIG...
IF EXIST "%STEAM_PATH%\config" (
    RD /S /Q "%STEAM_PATH%\config" >nul 2>&1
    IF EXIST "%STEAM_PATH%\config" (
        echo  [✗] Не удалось удалить config (файлы заняты?)
    ) ELSE (
        echo  [✓] config — удалено успешно
    )
) ELSE (
    echo  [~] config — папка не найдена
)

:: ============================================================
:: ШАГ 6: Удаление папки userdata
:: ============================================================
echo  [*] Удаление папки USERDATA...
IF EXIST "%STEAM_PATH%\userdata" (
    RD /S /Q "%STEAM_PATH%\userdata" >nul 2>&1
    IF EXIST "%STEAM_PATH%\userdata" (
        echo  [✗] Не удалось удалить userdata (файлы заняты?)
    ) ELSE (
        echo  [✓] userdata — удалено успешно
    )
) ELSE (
    echo  [~] userdata — папка не найдена
)

:: ============================================================
:: ШАГ 7: Очистка реестра Steam
:: ============================================================
echo.
echo  [*] Очистка ключей реестра Steam...

:: HKCU - пользовательские ключи
REG DELETE "HKCU\SOFTWARE\Valve\Steam" /f >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    echo  [✓] HKCU\SOFTWARE\Valve\Steam — удалено
) ELSE (
    echo  [~] HKCU\SOFTWARE\Valve\Steam — не найден или уже удалён
)

REG DELETE "HKCU\SOFTWARE\Valve" /f >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    echo  [✓] HKCU\SOFTWARE\Valve — удалено
) ELSE (
    echo  [~] HKCU\SOFTWARE\Valve — не найден
)

:: HKLM - системные ключи
REG DELETE "HKLM\SOFTWARE\Valve\Steam" /f >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    echo  [✓] HKLM\SOFTWARE\Valve\Steam — удалено
) ELSE (
    echo  [~] HKLM\SOFTWARE\Valve\Steam — не найден
)

REG DELETE "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" /f >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    echo  [✓] HKLM\SOFTWARE\WOW6432Node\Valve\Steam — удалено
) ELSE (
    echo  [~] HKLM\SOFTWARE\WOW6432Node\Valve\Steam — не найден
)

REG DELETE "HKLM\SOFTWARE\WOW6432Node\Valve" /f >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    echo  [✓] HKLM\SOFTWARE\WOW6432Node\Valve — удалено
) ELSE (
    echo  [~] HKLM\SOFTWARE\WOW6432Node\Valve — не найден
)

:: Автозапуск Steam
REG DELETE "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "Steam" /f >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    echo  [✓] Автозапуск Steam из реестра — удалён
) ELSE (
    echo  [~] Автозапуск Steam — не найден
)

:: ============================================================
:: ШАГ 8: Итог
:: ============================================================
echo.
echo  ╔══════════════════════════════════════════════════════════╗
echo  ║            ✓  ОЧИСТКА ЗАВЕРШЕНА УСПЕШНО  ✓              ║
echo  ╠══════════════════════════════════════════════════════════╣
echo  ║  Удалено:                                               ║
echo  ║   • Папка logs                                          ║
echo  ║   • Папка config                                        ║
echo  ║   • Папка userdata                                      ║
echo  ║   • Ключи реестра Valve/Steam (HKCU + HKLM)            ║
echo  ║   • Запись автозапуска Steam                            ║
echo  ╚══════════════════════════════════════════════════════════╝
echo.
echo  Нажмите любую клавишу для выхода...
pause >nul
EXIT /B 0

:END_ERROR
echo.
echo  [✗] Скрипт завершён с ошибкой.
echo  Нажмите любую клавишу для выхода...
pause >nul
EXIT /B 1

:END_CANCEL
echo  Нажмите любую клавишу для выхода...
pause >nul
EXIT /B 0
