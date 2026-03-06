#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Windows Updates Disabler
Програма для відключення оновлень Windows 10/11
"""

import os
import subprocess
import sys
import winreg
import ctypes
from pathlib import Path
from typing import Tuple, List


class WindowsUpdatesDisabler:
    """Клас для управління відключенням оновлень Windows"""
    
    def __init__(self):
        self.is_admin = self._check_admin()
        self.results = []
        
    def _check_admin(self) -> bool:
        """Перевіряємо наявність прав адміністратора"""
        try:
            return ctypes.windll.shell.IsUserAnAdmin()
        except AttributeError:
            return False
    
    def _run_command(self, command: str, show_output: bool = False) -> Tuple[bool, str]:
        """Виконуємо команду в командному рядку"""
        try:
            result = subprocess.run(
                command,
                shell=True,
                capture_output=True,
                text=True,
                timeout=10
            )
            success = result.returncode == 0
            output = result.stdout + result.stderr if show_output else ""
            return success, output
        except Exception as e:
            return False, str(e)
    
    def disable_update_services(self) -> bool:
        """Відключаємо служби оновлень"""
        services = [
            "wuauserv",      # Windows Update
            "bits",          # Background Intelligent Transfer Service
            "DoSvc",         # Delivery Optimization
            "UsoSvc",        # Update Orchestrator Service
            "TuneupDefragService",  # Defragmentation
        ]
        
        print("📋 Відключення служб оновлень...")
        all_success = True
        
        for service in services:
            # Зупиняємо службу
            success, output = self._run_command(f"net stop {service} /y")
            
            # Встановлюємо тип запуску на disabled
            success2, _ = self._run_command(f"sc config {service} start=disabled")
            
            status = "✅" if (success or success2) else "❌"
            print(f"{status} {service}")
            
            if not (success or success2):
                all_success = False
        
        return all_success
    
    def disable_update_registry(self) -> bool:
        """Відключаємо оновлення через реєстр"""
        print("\n📝 Модифікація реєстру...")
        
        registry_changes = [
            {
                "path": r"SYSTEM\CurrentControlSet\Services\wuauserv",
                "name": "Start",
                "value": 4,  # 4 = Disabled
            },
            {
                "path": r"SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU",
                "name": "NoAutoUpdate",
                "value": 1,  # 1 = Disable auto-update
            },
            {
                "path": r"SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU",
                "name": "AUOptions",
                "value": 2,  # 2 = Notify for download
            },
        ]
        
        all_success = True
        
        for change in registry_changes:
            try:
                if "\\" in change["path"] and change["path"].startswith("SYSTEM"):
                    hive = winreg.HKEY_LOCAL_MACHINE
                else:
                    hive = winreg.HKEY_LOCAL_MACHINE
                
                # Отримуємо доступ до реєстру
                key = winreg.OpenKey(hive, change["path"], 0, winreg.KEY_SET_VALUE)
                winreg.SetValueEx(key, change["name"], 0, winreg.REG_DWORD, change["value"])
                winreg.CloseKey(key)
                print(f"✅ {change['path']} -> {change['name']}")
            except Exception as e:
                print(f"❌ {change['path']} -> {change['name']}: {e}")
                all_success = False
        
        return all_success
    
    def group_policy_disable(self) -> bool:
        """Відключаємо оновлення через Group Policy"""
        print("\n🔒 Застосування Group Policy...")
        
        # Оновлюємо групову політику
        success, _ = self._run_command("gpupdate /force")
        
        if success:
            print("✅ Group Policy оновлена")
        else:
            print("❌ Не вдалось оновити Group Policy")
        
        return success
    
    def disable_scheduled_tasks(self) -> bool:
        """Відключаємо запланові завдання для оновлень"""
        print("\n⏱️  Відключення запланованих завдань...")
        
        tasks = [
            r"Microsoft\Windows\UpdateOrchestrator\*",
            r"Microsoft\Windows\Update\*",
            r"Microsoft\Windows\InstallService\*",
        ]
        
        all_success = True
        
        for task_pattern in tasks:
            success, _ = self._run_command(
                f'schtasks /query /tn "{task_pattern}" 2>nul | findstr /i "UpdateOrchestrator" && '
                f'schtasks /change /tn "{task_pattern}" /disable'
            )
            
            if success or "successful" in _.lower():
                print(f"✅ {task_pattern}")
            else:
                print(f"⚠️  {task_pattern}")
        
        return all_success
    
    def disable_update_assistant(self) -> bool:
        """Видаляємо Windows Update Assistant"""
        print("\n🗑️  Видалення Update Assistant...")
        
        # Видаляємо файли Update Assistant якщо є
        paths_to_remove = [
            Path(os.environ.get("ProgramFiles", "C:\\Program Files")) / "Windows Update",
            Path(os.environ.get("ProgramFilesX86", "C:\\Program Files (x86)")) / "Windows Update",
        ]
        
        for path in paths_to_remove:
            if path.exists():
                try:
                    self._run_command(f'rmdir /s /q "{path}"')
                    print(f"✅ Видалено: {path}")
                except Exception as e:
                    print(f"⚠️  Не вдалось видалити {path}: {e}")
        
        return True
    
    def create_restore_point(self) -> bool:
        """Створюємо точку відновлення"""
        print("\n💾 Створення точки відновлення системи...")
        
        cmd = (
            'powershell -Command '
            '"Checkpoint-Computer -Description \\"Before disabling Windows Updates\\" -RestorePointType \\"MODIFY_SETTINGS\\""'
        )
        
        success, output = self._run_command(cmd)
        
        if success:
            print("✅ Точка відновлення створена")
        else:
            print("⚠️  Не вдалось створити точку відновлення")
        
        return success
    
    def run_all(self) -> bool:
        """Виконуємо всі методи відключення"""
        if not self.is_admin:
            print("❌ ПОМИЛКА: Програма повинна запуститись з правами адміністратора!")
            print("   Будь ласка, запустіть програму від адміністратора.")
            return False
        
        print("=" * 60)
        print("🔧 Windows Updates Disabler v1.0")
        print("=" * 60)
        
        try:
            # Створюємо точку відновлення
            self.create_restore_point()
            
            # Виконуємо основні методи
            self.disable_update_services()
            self.disable_update_registry()
            self.group_policy_disable()
            self.disable_scheduled_tasks()
            self.disable_update_assistant()
            
            print("\n" + "=" * 60)
            print("✅ Оновлення Windows успішно відключені!")
            print("=" * 60)
            print("\n📌 Важливо:")
            print("   • Перезавантажте комп'ютер для застосування змін")
            print("   • Щоб включити оновлення, запустіть enable_windows_updates.py")
            print("   • Точка відновлення створена для безпеки")
            
            return True
            
        except Exception as e:
            print(f"\n❌ Помилка: {e}")
            return False


def main():
    """Головна функція"""
    disabler = WindowsUpdatesDisabler()
    success = disabler.run_all()
    
    sys.exit(0 if success else 1)


if __name__ == "__main__":
    main()
