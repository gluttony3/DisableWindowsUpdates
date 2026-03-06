@echo off
REM Quick Start Guide and Menu
REM Відключення Оновлень Windows

setlocal enabledelayedexpansion

:menu
cls
echo.
echo ================================================================================
echo  Windows Updates Manager v1.0
echo ================================================================================
echo.
echo Виберіть дію:
echo.
echo  1) Відключити оновлення Windows (Batch)
echo  2) Включити оновлення Windows (Batch)
echo  3) Відключити оновлення Windows (PowerShell)
echo  4) Включити оновлення Windows (PowerShell)
echo  5) Відключити оновлення Windows (Python)
echo  6) Включити оновлення Windows (Python)
echo  7) Показати інформацію про систему
echo  8) Вихід
echo.
set /p choice="Введіть номер [1-8]: "

if "%choice%"=="1" goto disable_batch
if "%choice%"=="2" goto enable_batch
if "%choice%"=="3" goto disable_ps
if "%choice%"=="4" goto enable_ps
if "%choice%"=="5" goto disable_python
if "%choice%"=="6" goto enable_python
if "%choice%"=="7" goto sysinfo
if "%choice%"=="8" goto exit_menu
goto menu

:disable_batch
cls
echo.
echo ================================================================================
echo  Запуск: disable_windows_updates.bat
echo ================================================================================
echo.
if exist "disable_windows_updates.bat" (
    call disable_windows_updates.bat
) else (
    echo ERROR: File not found - disable_windows_updates.bat
    echo.
    pause
)
goto menu

:enable_batch
cls
echo.
echo ================================================================================
echo  Запуск: enable_windows_updates.bat
echo ================================================================================
echo.
if exist "enable_windows_updates.bat" (
    call enable_windows_updates.bat
) else (
    echo ERROR: File not found - enable_windows_updates.bat
    echo.
    pause
)
goto menu

:disable_ps
cls
echo.
echo ================================================================================
echo  Запуск: Disable-WindowsUpdates.ps1
echo ================================================================================
echo.
if exist "Disable-WindowsUpdates.ps1" (
    powershell -ExecutionPolicy Bypass -File "Disable-WindowsUpdates.ps1" -Force
) else (
    echo ERROR: File not found - Disable-WindowsUpdates.ps1
    echo.
    pause
)
goto menu

:enable_ps
cls
echo.
echo ================================================================================
echo  Запуск: Enable-WindowsUpdates.ps1
echo ================================================================================
echo.
if exist "Enable-WindowsUpdates.ps1" (
    powershell -ExecutionPolicy Bypass -File "Enable-WindowsUpdates.ps1" -Force
) else (
    echo ERROR: File not found - Enable-WindowsUpdates.ps1
    echo.
    pause
)
goto menu

:disable_python
cls
echo.
echo ================================================================================
echo  Запуск: disable_windows_updates.py
echo ================================================================================
echo.
if exist "disable_windows_updates.py" (
    python disable_windows_updates.py
) else (
    echo ERROR: File not found - disable_windows_updates.py
    echo.
    pause
)
goto menu

:enable_python
cls
echo.
echo ================================================================================
echo  Запуск: enable_windows_updates.py
echo ================================================================================
echo.
if exist "enable_windows_updates.py" (
    python enable_windows_updates.py
) else (
    echo ERROR: File not found - enable_windows_updates.py
    echo.
    pause
)
goto menu

:sysinfo
cls
echo.
echo ================================================================================
echo  Інформація про систему
echo ================================================================================
echo.
systeminfo
echo.
echo ================================================================================
echo  Статус служб оновлень
echo ================================================================================
echo.
echo Windows Update:
sc query wuauserv | findstr /i "state"
echo.
echo Background Intelligent Transfer Service:
sc query bits | findstr /i "state"
echo.
echo Delivery Optimization:
sc query DoSvc | findstr /i "state"
echo.
echo Update Orchestrator Service:
sc query UsoSvc | findstr /i "state"
echo.
pause
goto menu

:exit_menu
exit /b 0
