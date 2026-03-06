# Windows Updates Enabler - PowerShell Version
# Програма для включення оновлень Windows 10/11

#Requires -RunAsAdministrator

param(
    [switch]$Force
)

function Write-Header {
    Clear-Host
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host "  Windows Updates Enabler v1.0 (PowerShell)" -ForegroundColor Cyan
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Test-Administrator {
    $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Enable-UpdateServices {
    Write-Host "[*] Starting Windows Update services..." -ForegroundColor Yellow
    
    $services = @(
        "wuauserv",      # Windows Update
        "bits",          # Background Intelligent Transfer Service
        "DoSvc",         # Delivery Optimization
        "UsoSvc"         # Update Orchestrator Service
    )
    
    foreach ($service in $services) {
        try {
            Set-Service -Name $service -StartupType Automatic -ErrorAction SilentlyContinue
            Start-Service -Name $service -ErrorAction SilentlyContinue | Out-Null
            Write-Host "[OK] Service '$service' enabled" -ForegroundColor Green
        }
        catch {
            Write-Host "[!] Error enabling '$service': $_" -ForegroundColor Yellow
        }
    }
}

function Enable-UpdateRegistry {
    Write-Host "`n[*] Restoring registry..." -ForegroundColor Yellow
    
    $registryPaths = @(
        @{
            Path = "HKLM:\SYSTEM\CurrentControlSet\Services\wuauserv"
            Name = "Start"
            Value = 2
        },
        @{
            Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
            Name = "NoAutoUpdate"
            Value = 0
        },
        @{
            Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
            Name = "AUOptions"
            Value = 3
        }
    )
    
    foreach ($reg in $registryPaths) {
        try {
            if (-not (Test-Path $reg.Path)) {
                New-Item -Path $reg.Path -Force | Out-Null
            }
            New-ItemProperty -Path $reg.Path -Name $reg.Name -Value $reg.Value -PropertyType DWord -Force | Out-Null
            Write-Host "[OK] Registry: $($reg.Name) restored" -ForegroundColor Green
        }
        catch {
            Write-Host "[!] Error setting registry '$($reg.Name)': $_" -ForegroundColor Yellow
        }
    }
}

function Enable-ScheduledTasks {
    Write-Host "`n[*] Enabling scheduled tasks..." -ForegroundColor Yellow
    
    $tasks = @(
        "Microsoft\Windows\UpdateOrchestrator\Regular Maintenance",
        "Microsoft\Windows\UpdateOrchestrator\Reboot",
        "Microsoft\Windows\UpdateOrchestrator\Schedule Scan",
        "Microsoft\Windows\Update\Scheduled Start"
    )
    
    foreach ($task in $tasks) {
        try {
            Enable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue | Out-Null
            Write-Host "[OK] Task '$task' enabled" -ForegroundColor Green
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
        Write-Host "This script will enable Windows Updates." -ForegroundColor Yellow
        Write-Host ""
        $confirm = Read-Host "Do you want to continue? (yes/no)"
        
        if ($confirm -ne "yes") {
            Write-Host "Operation cancelled." -ForegroundColor Yellow
            exit 0
        }
    }
    
    Write-Host ""
    
    Enable-UpdateServices
    Enable-UpdateRegistry
    Enable-ScheduledTasks
    Update-GroupPolicy
    
    Write-Host "`n================================================================================" -ForegroundColor Cyan
    Write-Host "  SUCCESS: Windows Updates have been enabled!" -ForegroundColor Green
    Write-Host "================================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "IMPORTANT:" -ForegroundColor Yellow
    Write-Host "  * Reboot your computer to apply all changes"
    Write-Host "  * Windows will start searching for and installing updates"
    Write-Host "  * This may take some time depending on available updates"
    Write-Host ""
    
    Read-Host "Press Enter to exit"
}

Main
