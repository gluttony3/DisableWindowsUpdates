#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Windows Updates Enabler
Програма для включення оновлень Windows 10/11
"""

import os
import subprocess
import sys
import winreg
import ctypes
from typing import Tuple


class WindowsUpdatesEnabler:
    """Клас для включення оновлень Windows"""
    
    def __init__(self):
        self.is_admin = self._check_admin()
        
    def _check_admin(self) -> bool:
        """Перевіряємо наявність прав адміністратора"""
        try:
            return ctypes.windll.shell.IsUserAnAdmin()
        except AttributeError:
            return False
    
    def _run_command(self, command: str) -> Tuple[bool, str]:
        """Виконуємо команду в командному рядку"""
        try:
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=10
            )
            return result.returncode == 0, result.stdout + result.stderr
        except Exception as e:
            return False, str(e)
    
    def enable_update_services(self) -> bool:
        """Включаємо служби оновлень"""
        services = [
            "wuauserv",      # Windows Update
            "bits",          # Background Intelligent Transfer Service
            "DoSvc",         # Delivery Optimization
            "UsoSvc",        # Update Orchestrator Service
        ]
        
        print("📋 Включення служб оновлень...")
        
        for service in services:
            # Встановлюємо тип запуску на automatic
            success1, _ = self._run_command(f"sc config {service} start=auto")
            
            # Запускаємо службу
            success2, _ = self._run_command(f"net start {service}")
            
            status = "✅" if (success1 or success2) else "❌"
            print(f"{status} {service}")
        
        return True
    
    def enable_update_registry(self) -> bool:
        """Включаємо оновлення через реєстр"""
        print("\n📝 Відновлення реєстру...")
        
        registry_changes = [
            {
                "path": r"SYSTEM\CurrentControlSet\Services\wuauserv",
                "name": "Start",
                "value": 2,  # 2 = Auto start
            },
            {
                "path": r"SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU",
                "name": "NoAutoUpdate",
                "value": 0,  # 0 = Enable auto-update
            },
            {
                "path": r"SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU",
                "name": "AUOptions",
                "value": 3,  # 3 = Auto download and install
            },
        ]
        
        for change in registry_changes:
            try:
                key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, change["path"], 0, winreg.KEY_SET_VALUE)
                winreg.SetValueEx(key, change["name"], 0, winreg.REG_DWORD, change["value"])
                winreg.CloseKey(key)
                print(f"✅ {change['path']} -> {change['name']}")
            except Exception as e:
                print(f"⚠️  {change['path']}: {e}")
        
        return True
    
    def enable_scheduled_tasks(self) -> bool:
        """Включаємо запланові завдання"""
        print("\n⏱️  Включення запланованих завдань...")
        
        tasks = [
            r"Microsoft\Windows\UpdateOrchestrator\Regular Maintenance",
            r"Microsoft\Windows\UpdateOrchestrator\Reboot",
            r"Microsoft\Windows\Update\Scheduled Start",
        ]
        
        for task in tasks:
            success, _ = self._run_command(f'schtasks /change /tn "{task}" /enable')
            status = "✅" if success else "⚠️"
            print(f"{status} {task}")
        
        return True
    
    def group_policy_update(self) -> bool:
        """Оновлюємо групову політику"""
        print("\n🔒 Оновлення Group Policy...")
        
        success, _ = self._run_command("gpupdate /force")
        
        if success:
            print("✅ Group Policy оновлена")
        else:
            print("⚠️  Group Policy оновлення завершено")
        
        return True
    
    def run_all(self) -> bool:
        """Виконуємо включення всіх компонентів"""
        if not self.is_admin:
            print("❌ ПОМИЛКА: Програма повинна запуститись з правами адміністратора!")
            print("   Будь ласка, запустіть програму від адміністратора.")
            return False
        
        print("=" * 60)
        print("🔓 Windows Updates Enabler v1.0")
        print("=" * 60)
        
        try:
            self.enable_update_services()
            self.enable_update_registry()
            self.enable_scheduled_tasks()
            self.group_policy_update()
            
            print("\n" + "=" * 60)
            print("✅ Оновлення Windows успішно включені!")
            print("=" * 60)
            print("\n📌 Важливо:")
            print("   • Перезавантажте комп'ютер для застосування змін")
            print("   • Windows почне шукати та встановлювати оновлення")
            
            return True
            
        except Exception as e:
            print(f"\n❌ Помилка: {e}")
            return False


def main():
    """Головна функція"""
    enabler = WindowsUpdatesEnabler()
    success = enabler.run_all()
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
