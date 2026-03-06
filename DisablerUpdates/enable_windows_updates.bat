@echo off
REM Windows Updates Enabler
REM Програма для включення оновлень Windows 10/11

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
echo  Windows Updates Enabler v1.0
echo ================================================================================
echo.

echo [1/4] Starting Windows Update services...

REM Включаємо послуги
for %%S in (wuauserv bits DoSvc UsoSvc) do (
    sc config %%S start=auto >nul 2>&1
    net start %%S >nul 2>&1
    echo [OK] Service %%S enabled
)

echo.
echo [2/4] Restoring registry...

REM Відновлюємо реєстр
reg add "HKLM\SYSTEM\CurrentControlSet\Services\wuauserv" /v Start /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 3 /f >nul 2>&1

echo [OK] Registry restored

echo.
echo [3/4] Enabling scheduled tasks...

REM Включаємо завдання
schtasks /change /tn "Microsoft\Windows\UpdateOrchestrator\Regular Maintenance" /enable >nul 2>&1
schtasks /change /tn "Microsoft\Windows\Update\Scheduled Start" /enable >nul 2>&1
schtasks /change /tn "Microsoft\Windows\UpdateOrchestrator\Reboot" /enable >nul 2>&1

echo [OK] Scheduled tasks enabled

echo.
echo [4/4] Applying Group Policy...
gpupdate /force >nul 2>&1
echo [OK] Group Policy updated

echo.
echo ================================================================================
echo  SUCCESS: Windows Updates have been enabled!
echo ================================================================================
echo.
echo IMPORTANT:
echo  * Reboot your computer to apply all changes
echo  * Windows will start searching for and installing updates
echo  * This may take some time depending on available updates
echo.

pause
exit /b 0
