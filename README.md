# Windows Updates Disabler/Enabler

A lightweight toolkit to fully disable or re-enable Windows Update on Windows 10 and Windows 11. Supports Batch, PowerShell, and Python — run whichever fits your workflow.

> **Warning:** Disabling Windows Update reduces your system's security. Use responsibly and re-enable updates periodically to apply critical security patches.

---

## Features

- Stops all Windows Update-related services (`wuauserv`, `BITS`, `DoSvc`, `UsoSvc`)
- Modifies registry keys to prevent services from restarting
- Disables scheduled update tasks via Task Scheduler
- Applies Group Policy settings for deeper control
- Automatically creates a System Restore Point before making any changes
- Fully reversible — enable updates back with a single script

---

## Project Files

| File | Purpose |
|------|---------|
| `disable_windows_updates.bat` | **Recommended** — Disable updates (Batch) |
| `enable_windows_updates.bat` | **Recommended** — Enable updates (Batch) |
| `Disable-WindowsUpdates.ps1` | Disable updates (PowerShell) |
| `Enable-WindowsUpdates.ps1` | Enable updates (PowerShell) |
| `disable_windows_updates.py` | Disable updates (Python) |
| `enable_windows_updates.py` | Enable updates (Python) |
| `Menu.bat` | Interactive menu to choose an action |

---

## Requirements

- Windows 10 or Windows 11
- Administrator privileges
- Python 3.x (only for `.py` scripts)

---

## Usage

### Option 1: Batch (Recommended)

1. Right-click `disable_windows_updates.bat` (or `enable_windows_updates.bat`)
2. Select **Run as administrator**
3. Follow the on-screen prompts
4. Reboot your computer

### Option 2: Interactive Menu

```bat
Menu.bat
```

Right-click and run as administrator. Choose disable or enable from the menu.

### Option 3: PowerShell

```powershell
# Allow script execution (one-time setup)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Disable updates
powershell -ExecutionPolicy Bypass -File "Disable-WindowsUpdates.ps1"

# Enable updates
powershell -ExecutionPolicy Bypass -File "Enable-WindowsUpdates.ps1"
```

### Option 4: Python

```bash
# Disable updates
python disable_windows_updates.py

# Enable updates
python enable_windows_updates.py
```

> Run your terminal (CMD or PowerShell) as Administrator before executing Python scripts.

---

## What Gets Modified

### Services (set to Disabled)

| Service | Display Name | Role |
|---------|-------------|------|
| `wuauserv` | Windows Update | Core update service |
| `bits` | Background Intelligent Transfer Service | Downloads updates |
| `DoSvc` | Delivery Optimization | Distributes updates |
| `UsoSvc` | Update Orchestrator Service | Manages update workflow |

### Registry Keys

```
HKLM\SYSTEM\CurrentControlSet\Services\wuauserv  →  Start = 4 (Disabled)
HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU  →  NoAutoUpdate = 1
HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU  →  AUOptions = 2
```

### Scheduled Tasks (Disabled)

```
Microsoft\Windows\UpdateOrchestrator\Regular Maintenance
Microsoft\Windows\UpdateOrchestrator\Reboot
Microsoft\Windows\UpdateOrchestrator\Schedule Scan
Microsoft\Windows\Update\Scheduled Start
```

---

## Re-enabling Updates

Run the enable script at any time:

```bat
enable_windows_updates.bat
```

Then reboot. All services, registry keys, and scheduled tasks will be restored to their defaults.

---

## Reverting with System Restore

If something goes wrong, restore from the automatically created restore point:

1. Press `Win + R`, type `rstrui.exe`, press Enter
2. Select the restore point labeled **"Before disabling Windows Updates"**
3. Follow the wizard and reboot

---

## Troubleshooting

**"Access Denied" error**
- Make sure you run the script as Administrator
- Temporarily disable your antivirus (some flag registry modifications)

**Script won't run**
- For `.ps1` files, set the execution policy: `Set-ExecutionPolicy RemoteSigned`
- For `.bat` files, right-click → Run as administrator

**Updates still installing after running the script**
- Reboot your PC — changes take effect after a restart
- Verify services are disabled: `sc query wuauserv`
- Re-run the disable script as Administrator

---

## Security Considerations

Disabling updates leaves your system exposed to known vulnerabilities. Recommended practice:

1. Run `enable_windows_updates.bat` once a month
2. Install available updates manually
3. Run `disable_windows_updates.bat` again afterwards

Keep Windows Defender and your firewall active at all times.

---

## License

This project is intended for educational purposes and system administration use.
