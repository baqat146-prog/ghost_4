@echo off
:: ============================================================
::  STEAM CLEANER v2.0 - Очистка Steam + Выход из аккаунтов
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
title STEAM CLEANER v2.0 - Запущен от имени Администратора

cls
echo.
echo  ==========================================================
echo   STEAM CLEANER v2.0  by SteamSweep
echo   Очистка логов, данных, реестра + Выход из аккаунтов
echo  ==========================================================
echo.

:: ============================================================
:: ШАГ 1: Поиск расположения Steam
:: ============================================================
echo  [*] Поиск установленного Steam...
echo.

SET "STEAM_PATH="

FOR /F "tokens=2*" %%A IN ('reg query "HKCU\SOFTWARE\Valve\Steam" /v "SteamPath" 2^>nul') DO (
    SET "STEAM_PATH=%%B"
)
IF NOT DEFINED STEAM_PATH (
    FOR /F "tokens=2*" %%A IN ('reg query "HKLM\SOFTWARE\Valve\Steam" /v "InstallPath" 2^>nul') DO (
        SET "STEAM_PATH=%%B"
    )
)
IF NOT DEFINED STEAM_PATH (
    FOR /F "tokens=2*" %%A IN ('reg query "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" /v "InstallPath" 2^>nul') DO (
        SET "STEAM_PATH=%%B"
    )
)
IF NOT DEFINED STEAM_PATH (
    IF EXIST "C:\Program Files (x86)\Steam\steam.exe" SET "STEAM_PATH=C:\Program Files (x86)\Steam"
)
IF NOT DEFINED STEAM_PATH (
    IF EXIST "C:\Program Files\Steam\steam.exe" SET "STEAM_PATH=C:\Program Files\Steam"
)
IF NOT DEFINED STEAM_PATH (
    IF EXIST "%LOCALAPPDATA%\Steam\steam.exe" SET "STEAM_PATH=%LOCALAPPDATA%\Steam"
)

IF NOT DEFINED STEAM_PATH (
    echo  [X] Steam НЕ НАЙДЕН на этом компьютере!
    echo.
    echo  Введите путь вручную (например: D:\Steam) или Enter для выхода:
    echo.
    SET /P "STEAM_PATH=  Путь: "
    IF NOT DEFINED STEAM_PATH GOTO :END_ERROR
    IF NOT EXIST "%STEAM_PATH%\steam.exe" (
        echo.
        echo  [X] По указанному пути steam.exe не найден. Выход.
        GOTO :END_ERROR
    )
)

SET "STEAM_PATH=%STEAM_PATH:/=\%"

echo  [OK] Steam найден:
echo       %STEAM_PATH%
echo.

:: ============================================================
:: ШАГ 2: Закрытие Steam
:: ============================================================
echo  [*] Проверка: запущен ли Steam...
tasklist /FI "IMAGENAME eq steam.exe" 2>nul | find /I "steam.exe" >nul
IF %ERRORLEVEL% EQU 0 (
    echo  [!] Steam запущен. Закрываем принудительно...
    taskkill /F /IM steam.exe >nul 2>&1
    taskkill /F /IM steamwebhelper.exe >nul 2>&1
    taskkill /F /IM steamservice.exe >nul 2>&1
    timeout /t 2 /nobreak >nul
    echo  [OK] Steam закрыт.
) ELSE (
    echo  [OK] Steam не запущен. Продолжаем.
)
echo.

:: ============================================================
:: ШАГ 3: Показ найденных аккаунтов
:: ============================================================
echo  [*] Поиск сохранённых аккаунтов Steam...
echo.

SET "ACCOUNTS_FOUND=0"
SET "LOGINUSERS=%STEAM_PATH%\config\loginusers.vdf"

IF EXIST "%LOGINUSERS%" (
    FOR /F "usebackq tokens=*" %%L IN (`findstr /I "AccountName" "%LOGINUSERS%" 2^>nul`) DO (
        SET /A ACCOUNTS_FOUND+=1
        echo      %%L
    )
    echo.
    IF %ACCOUNTS_FOUND% GTR 0 (
        echo  [!] Найдено аккаунтов: %ACCOUNTS_FOUND% — все будут разлогинены
    ) ELSE (
        echo  [~] loginusers.vdf пустой
    )
) ELSE (
    echo  [~] loginusers.vdf не найден (аккаунты не сохранены)
)
echo.

:: ============================================================
:: ШАГ 4: Подтверждение
:: ============================================================
echo  ----------------------------------------------------------
echo   Будут выполнены следующие действия:
echo.
echo   ВЫХОД ИЗ АККАУНТОВ:
echo    - loginusers.vdf   (список сохранённых аккаунтов)
echo    - config.vdf       (токены сессии / автовход)
echo    - localconfig.vdf  (локальные данные пользователя)
echo    - AppData\Steam    (кэш сессии Windows)
echo    - AutoLoginUser    (сброс в реестре)
echo.
echo   ОЧИСТКА ПАПОК:
echo    - logs, config, userdata
echo.
echo   ОЧИСТКА РЕЕСТРА:
echo    - Все ключи Valve\Steam (HKCU + HKLM)
echo  ----------------------------------------------------------
echo.
SET /P "CONFIRM=  Продолжить? (Y/N): "
IF /I NOT "%CONFIRM%"=="Y" (
    echo.
    echo  [!] Операция отменена пользователем.
    GOTO :END_CANCEL
)
echo.

:: ============================================================
:: ШАГ 5: Выход из аккаунтов Steam
:: ============================================================
echo  ----------------------------------------------------------
echo   ВЫХОД ИЗ АККАУНТОВ
echo  ----------------------------------------------------------

:: loginusers.vdf — список всех сохранённых аккаунтов
IF EXIST "%STEAM_PATH%\config\loginusers.vdf" (
    DEL /F /Q "%STEAM_PATH%\config\loginusers.vdf" >nul 2>&1
    IF EXIST "%STEAM_PATH%\config\loginusers.vdf" (
        echo  [X] loginusers.vdf — не удалось удалить
    ) ELSE (
        echo  [OK] loginusers.vdf — удалён (все аккаунты вышли)
    )
) ELSE (
    echo  [~] loginusers.vdf — не найден
)

:: config.vdf — токены сессии и автовход
IF EXIST "%STEAM_PATH%\config\config.vdf" (
    DEL /F /Q "%STEAM_PATH%\config\config.vdf" >nul 2>&1
    IF EXIST "%STEAM_PATH%\config\config.vdf" (
        echo  [X] config.vdf — не удалось удалить
    ) ELSE (
        echo  [OK] config.vdf — удалён (токены сессии очищены)
    )
) ELSE (
    echo  [~] config.vdf — не найден
)

:: localconfig.vdf — локальные данные пользователя
IF EXIST "%STEAM_PATH%\config\localconfig.vdf" (
    DEL /F /Q "%STEAM_PATH%\config\localconfig.vdf" >nul 2>&1
    echo  [OK] localconfig.vdf — удалён
) ELSE (
    echo  [~] localconfig.vdf — не найден
)

:: AppData\Roaming\Steam — кэш сессии Windows
IF EXIST "%APPDATA%\Steam" (
    RD /S /Q "%APPDATA%\Steam" >nul 2>&1
    echo  [OK] AppData\Roaming\Steam — очищен
) ELSE (
    echo  [~] AppData\Roaming\Steam — не найден
)

:: AppData\Local\Steam (если не папка установки)
IF EXIST "%LOCALAPPDATA%\Steam" (
    IF /I NOT "%LOCALAPPDATA%\Steam"=="%STEAM_PATH%" (
        RD /S /Q "%LOCALAPPDATA%\Steam" >nul 2>&1
        echo  [OK] AppData\Local\Steam — очищен
    )
)

:: Реестр: сброс автовхода
REG DELETE "HKCU\SOFTWARE\Valve\Steam" /v "AutoLoginUser" /f >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    echo  [OK] AutoLoginUser — сброшен (автовход отключён)
) ELSE (
    echo  [~] AutoLoginUser — не был установлен
)

REG DELETE "HKCU\SOFTWARE\Valve\Steam" /v "RememberPassword" /f >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
    echo  [OK] RememberPassword — сброшен
) ELSE (
    echo  [~] RememberPassword — не найден
)

REG DELETE "HKCU\SOFTWARE\Valve\Steam" /v "LastGameNameUsed" /f >nul 2>&1
REG DELETE "HKCU\SOFTWARE\Valve\Steam" /v "LastLoadedGame" /f >nul 2>&1

echo.

:: ============================================================
:: ШАГ 6: Очистка папок
:: ============================================================
echo  ----------------------------------------------------------
echo   ОЧИСТКА ПАПОК
echo  ----------------------------------------------------------

IF EXIST "%STEAM_PATH%\logs" (
    RD /S /Q "%STEAM_PATH%\logs" >nul 2>&1
    IF EXIST "%STEAM_PATH%\logs" (echo  [X] logs — не удалось) ELSE (echo  [OK] logs — удалено)
) ELSE (echo  [~] logs — не найдена)

IF EXIST "%STEAM_PATH%\config" (
    RD /S /Q "%STEAM_PATH%\config" >nul 2>&1
    IF EXIST "%STEAM_PATH%\config" (echo  [X] config — не удалось) ELSE (echo  [OK] config — удалено)
) ELSE (echo  [~] config — не найдена)

IF EXIST "%STEAM_PATH%\userdata" (
    RD /S /Q "%STEAM_PATH%\userdata" >nul 2>&1
    IF EXIST "%STEAM_PATH%\userdata" (echo  [X] userdata — не удалось) ELSE (echo  [OK] userdata — удалено)
) ELSE (echo  [~] userdata — не найдена)

echo.

:: ============================================================
:: ШАГ 7: Очистка реестра
:: ============================================================
echo  ----------------------------------------------------------
echo   ОЧИСТКА РЕЕСТРА
echo  ----------------------------------------------------------

REG DELETE "HKCU\SOFTWARE\Valve\Steam" /f >nul 2>&1
IF %ERRORLEVEL% EQU 0 (echo  [OK] HKCU\...\Valve\Steam — удалено) ELSE (echo  [~] HKCU\...\Valve\Steam — не найден)

REG DELETE "HKCU\SOFTWARE\Valve" /f >nul 2>&1
IF %ERRORLEVEL% EQU 0 (echo  [OK] HKCU\...\Valve — удалено) ELSE (echo  [~] HKCU\...\Valve — не найден)

REG DELETE "HKLM\SOFTWARE\Valve\Steam" /f >nul 2>&1
IF %ERRORLEVEL% EQU 0 (echo  [OK] HKLM\...\Valve\Steam — удалено) ELSE (echo  [~] HKLM\...\Valve\Steam — не найден)

REG DELETE "HKLM\SOFTWARE\WOW6432Node\Valve\Steam" /f >nul 2>&1
IF %ERRORLEVEL% EQU 0 (echo  [OK] HKLM\WOW6432Node\Valve\Steam — удалено) ELSE (echo  [~] HKLM\WOW6432Node\Valve\Steam — не найден)

REG DELETE "HKLM\SOFTWARE\WOW6432Node\Valve" /f >nul 2>&1
IF %ERRORLEVEL% EQU 0 (echo  [OK] HKLM\WOW6432Node\Valve — удалено) ELSE (echo  [~] HKLM\WOW6432Node\Valve — не найден)

REG DELETE "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "Steam" /f >nul 2>&1
IF %ERRORLEVEL% EQU 0 (echo  [OK] Автозапуск Steam — удалён) ELSE (echo  [~] Автозапуск Steam — не найден)

echo.

:: ============================================================
:: ИТОГ
:: ============================================================
echo  ==========================================================
echo   OK  ВСЯ ОЧИСТКА ЗАВЕРШЕНА УСПЕШНО
echo  ==========================================================
echo.
echo   ВЫХОД ИЗ АККАУНТОВ:
echo    [OK] loginusers.vdf удалён — все аккаунты разлогинены
echo    [OK] config.vdf удалён — сессии и токены сброшены
echo    [OK] AutoLoginUser сброшен — автовход отключён
echo    [OK] AppData\Steam очищен
echo.
echo   ПАПКИ: logs / config / userdata — очищены
echo   РЕЕСТР: Valve\Steam HKCU + HKLM — очищен
echo.
echo   При следующем запуске Steam потребует войти в аккаунт.
echo  ==========================================================
echo.
echo  Нажмите любую клавишу для выхода...
pause >nul
EXIT /B 0

:END_ERROR
echo.
echo  [X] Скрипт завершён с ошибкой.
pause >nul
EXIT /B 1

:END_CANCEL
echo  Нажмите любую клавишу для выхода...
pause >nul
EXIT /B 0
