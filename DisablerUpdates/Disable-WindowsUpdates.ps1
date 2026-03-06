# Windows Updates Disabler - PowerShell Version
# Програма для відключення оновлень Windows 10/11

#Requires -RunAsAdministrator

param(
    [switch]$Force,
    [switch]$RestorePoint = $true
)

function Write-Header {
    Clear-Host
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "  Windows Updates Disabler v1.0 (PowerShell)" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Test-Administrator {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Create-RestorePoint {
    Write-Host "[*] Creating system restore point..." -ForegroundColor Yellow
    try {
        Checkpoint-Computer -Description "Before disabling Windows Updates" -RestorePointType MODIFY_SETTINGS -ErrorAction SilentlyContinue
        Write-Host "[OK] Restore point created" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "[WARNING] Could not create restore point: $_" -ForegroundColor Yellow
        return $false
    }
}

function Disable-UpdateServices {
    Write-Host "`n[*] Stopping Windows Update services..." -ForegroundColor Yellow
    
    $services = @(
        "wuauserv",      # Windows Update
        "bits",          # Background Intelligent Transfer Service
        "DoSvc",         # Delivery Optimization
        "UsoSvc",        # Update Orchestrator Service
        "TuneupDefragService"
    )
    
    foreach ($service in $services) {
        try {
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue | Out-Null
            Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue | Out-Null
            Write-Host "[OK] Service '$service' disabled" -ForegroundColor Green
        }
        catch {
            Write-Host "[!] Error disabling '$service': $_" -ForegroundColor Yellow
        }
    }
}

function Disable-UpdateRegistry {
    Write-Host "`n[*] Modifying registry..." -ForegroundColor Yellow
    
    $registryPaths = @(
        @{
            Path = "HKLM:\SYSTEM\CurrentControlSet\Services\wuauserv"
            Name = "Start"
            Value = 4
        },
        @{
            Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
            Name = "NoAutoUpdate"
            Value = 1
        },
        @{
            Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
            Name = "AUOptions"
            Value = 2
        },
        @{
            Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
            Name = "DisableWindowsUpdateAccess"
            Value = 1
        }
    )
    
    foreach ($reg in $registryPaths) {
        try {
            if (-not (Test-Path $reg.Path)) {
                New-Item -Path $reg.Path -Force | Out-Null
            }
            New-ItemProperty -Path $reg.Path -Name $reg.Name -Value $reg.Value -PropertyType DWord -Force | Out-Null
            Write-Host "[OK] Registry: $($reg.Name) set to $($reg.Value)" -ForegroundColor Green
        }
        catch {
            Write-Host "[!] Error setting registry '$($reg.Name)': $_" -ForegroundColor Yellow
        }
    }
}

function Disable-ScheduledTasks {
    Write-Host "`n[*] Disabling scheduled tasks..." -ForegroundColor Yellow
    
    $tasks = @(
        "Microsoft\Windows\UpdateOrchestrator\Regular Maintenance",
        "Microsoft\Windows\UpdateOrchestrator\Reboot",
        "Microsoft\Windows\UpdateOrchestrator\Schedule Scan",
        "Microsoft\Windows\Update\Scheduled Start"
    )
    
    foreach ($task in $tasks) {
        try {
            Disable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue | Out-Null
            Write-Host "[OK] Task '$task' disabled" -ForegroundColor Green
        }
        catch {
            Write-Host "[!] Task not found: $task" -ForegroundColor Yellow
        }
    }
}

function Update-GroupPolicy {
    Write-Host "`n[*] Updating Group Policy..." -ForegroundColor Yellow
    try {
        & gpupdate /force | Out-Null
        Write-Host "[OK] Group Policy updated" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Error updating Group Policy: $_" -ForegroundColor Yellow
    }
}

function Main {
    if (-not (Test-Administrator)) {
        Write-Host "ERROR: This script requires Administrator privileges!" -ForegroundColor Red
        Write-Host "Please run PowerShell as Administrator." -ForegroundColor Red
        exit 1
    }
    
    Write-Header
    
    if (-not $Force) {
        Write-Host "WARNING: This script will disable Windows Updates." -ForegroundColor Yellow
        Write-Host "A system restore point will be created for safety." -ForegroundColor Yellow
        Write-Host ""
        $confirm = Read-Host "Do you want to continue? (yes/no)"
        
        if ($confirm -ne "yes") {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            exit 0
        }
    }
    
    Write-Host ""
    
    if ($RestorePoint) {
        Create-RestorePoint
    }
    
    Disable-UpdateServices
    Disable-UpdateRegistry
    Disable-ScheduledTasks
    Update-GroupPolicy
    
    Write-Host "`n================================================================================" -ForegroundColor Cyan
    Write-Host "  SUCCESS: Windows Updates have been disabled!" -ForegroundColor Green
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "IMPORTANT:" -ForegroundColor Yellow
    Write-Host "  * Reboot your computer to apply all changes"
    Write-Host "  * To enable updates again, run: Enable-WindowsUpdates.ps1"
    Write-Host "  * System restore point has been created for safety"
    Write-Host ""
    
    Read-Host "Press Enter to exit"
}

Main
