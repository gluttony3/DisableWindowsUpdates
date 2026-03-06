@echo off
REM Windows Updates Disabler
REM Програма для відключення оновлень Windows 10/11

setlocal enabledelayedexpansion

REM Перевірка прав адміністратора
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ================================
    echo  ERROR: Admin rights required!
    echo ================================
    echo.
    echo Please run this script as Administrator
    echo.
    pause
    exit /b 1
)

cls
echo.
echo ================================================================================
echo  Windows Updates Disabler v1.0
echo ================================================================================
echo.

REM Створюємо точку відновлення
echo [1/5] Creating system restore point...
powershell -Command "Checkpoint-Computer -Description 'Before disabling Windows Updates' -RestorePointType MODIFY_SETTINGS" >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Restore point created
) else (
    echo [WARNING] Could not create restore point
)

echo.
echo [2/5] Stopping Windows Update services...

REM Зупиняємо служби
for %%S in (wuauserv bits DoSvc UsoSvc) do (
    net stop %%S /y >nul 2>&1
    sc config %%S start=disabled >nul 2>&1
    echo [OK] Service %%S disabled
)

echo.
echo [3/5] Modifying registry...

REM Модифікуємо реєстр
reg add "HKLM\SYSTEM\CurrentControlSet\Services\wuauserv" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 2 /f >nul 2>&1

echo [OK] Registry modified

echo.
echo [4/5] Disabling scheduled tasks...

REM Відключаємо завдання
for /f "delims=" %%T in ('tasklist /fo list ^| findstr /i "svchost"') do (
    schtasks /change /tn "Microsoft\Windows\UpdateOrchestrator\Regular Maintenance" /disable >nul 2>&1
    schtasks /change /tn "Microsoft\Windows\Update\Scheduled Start" /disable >nul 2>&1
)

echo [OK] Scheduled tasks disabled

echo.
echo [5/5] Applying Group Policy...
gpupdate /force >nul 2>&1
echo [OK] Group Policy updated

echo.
echo ================================================================================
echo  SUCCESS: Windows Updates have been disabled!
echo ================================================================================
echo.
echo IMPORTANT:
echo  * Reboot your computer to apply all changes
echo  * To enable updates again, run enable_windows_updates.bat
echo  * System restore point created for safety
echo.

pause
exit /b 0
