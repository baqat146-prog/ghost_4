@echo off
setlocal enabledelayedexpansion

:: Проверка и запрос прав администратора
IF "%PROCESSOR_ARCHITECTURE%" EQU "amd64" (
>nul 2>&1 "%SYSTEMROOT%\SysWOW64\cacls.exe" "%SYSTEMROOT%\SysWOW64\config\system"
) ELSE (
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"
)

if '%errorlevel%' NEQ '0' (
    echo Запрос прав администратора...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params= %*
    echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params:"=""%", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"

echo ========================================
echo   Начинается глубокая очистка Steam
echo ========================================

:: 1. Поиск пути к Steam через реестр
for /f "tokens=2*" %%a in ('reg query "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Valve\Steam" /v "InstallPath" 2^>nul') do set "STEAM_PATH=%%b"

if not defined STEAM_PATH (
    for /f "tokens=2*" %%a in ('reg query "HKEY_CURRENT_USER\Software\Valve\Steam" /v "SteamPath" 2^>nul') do set "STEAM_PATH=%%b"
)

if not defined STEAM_PATH (
    echo [!] Ошибка: Steam не найден в реестре.
    pause
    exit /B
)

echo [+] Steam найден по адресу: "%STEAM_PATH%"

:: 2. Закрытие процессов Steam (на всякий случай)
taskkill /f /im steam.exe /t >nul 2>&1

:: 3. Удаление папок
echo [+] Очистка папок...

if exist "%STEAM_PATH%\logs" (
    rd /s /q "%STEAM_PATH%\logs"
    echo [OK] Логи удалены.
)
if exist "%STEAM_PATH%\userdata" (
    rd /s /q "%STEAM_PATH%\userdata"
    echo [OK] Userdata (аккаунты) удалена.
)
if exist "%STEAM_PATH%\config" (
    rd /s /q "%STEAM_PATH%\config"
    echo [OK] Конфигурация удалена.
)

:: 4. Очистка реестра
echo [+] Удаление следов в реестре...
reg delete "HKEY_CURRENT_USER\Software\Valve\Steam" /f >nul 2>&1
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\WOW6432Node\Valve\Steam" /f >nul 2>&1
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Valve\Steam" /f >nul 2>&1

echo ========================================
echo   Очистка успешно завершена!
echo ========================================
pause
