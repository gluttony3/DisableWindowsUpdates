# ТЕХНІЧНИЙ ПОСІБНИК - Windows Updates Disabler

## 📖 Зміст
1. [Що робить програма](#що-робить-програма)
2. [Технічні деталі](#технічні-деталі)
3. [Служби, які відключаються](#служби-які-відключаються)
4. [Реєстрові ключі](#реєстрові-ключі)
5. [Запланові завдання](#запланові-завдання)
6. [Вирішення проблем](#вирішення-проблем)
7. [Безпека](#безпека)

---

## Що робить програма

Програма **повністю відключає** все механізми оновлення Windows 10/11:

### 1️⃣ **Зупинення служб**
Останавливає кілька критичних сервісів які відповідають за завантаження та встановлення оновлень.

### 2️⃣ **Модифікація реєстру**
Змінює параметри реєстру Windows щоб запобігти автоматичному запуску служб оновлень.

### 3️⃣ **Деактивація запланованих завдань**
Відключає фонові завдання які регулярно перевіряють наявність оновлень.

### 4️⃣ **Групова політика**
Застосовує параметри групової політики для найвищого рівня контролю.

### 5️⃣ **Захист системи**
Автоматично створює точку відновлення перед всіма змінами.

---

## Технічні деталі

### Архітектура оновлень Windows

```
┌─────────────────────────────────────────┐
│  Windows Update Service (wuauserv)      │  ← Головна служба
├─────────────────────────────────────────┤
│  BITS (Background Download Service)     │  ← Завантаження
├─────────────────────────────────────────┤
│  Update Orchestrator Service (UsoSvc)   │  ← Управління
├─────────────────────────────────────────┤
│  Delivery Optimization (DoSvc)          │  ← Розповсюдження
└─────────────────────────────────────────┘
```

Програма **вимикає усі рівні** цієї архітектури.

---

## Служби, які відключаються

| Служба | Назва | Опис | Важливість |
|---------|--------|------|-----------|
| **wuauserv** | Windows Update | Головна служба оновлень | 🔴 Критична |
| **bits** | Background Intelligent Transfer Service | Завантажує оновлення | 🟠 Висока |
| **DoSvc** | Delivery Optimization | Розповсюджує оновлення | 🟡 Середня |
| **UsoSvc** | Update Orchestrator Service | Організує оновлення | 🔴 Критична |
| **TuneupDefragService** | Defragmentation | Дефрагментація | 🟡 Низька |

### Команди для вручну відключення:

```batch
REM Зупинення служб
net stop wuauserv /y
net stop bits /y
net stop DoSvc /y
net stop UsoSvc /y

REM Встановлення типу запуску на Disabled
sc config wuauserv start=disabled
sc config bits start=disabled
sc config DoSvc start=disabled
sc config UsoSvc start=disabled
```

---

## Реєстрові ключі

### Основні ключі які модифікуються:

#### 1. **Відключення служби Windows Update**
```
Шлях: HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\wuauserv
Ключ: Start
Значення: 4 (Disabled)
```

#### 2. **Груповa політика - Відключення автоматичних оновлень**
```
Шлях: HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU
Ключ: NoAutoUpdate
Значення: 1 (Отключено)
```

#### 3. **Групова політика - Тип оновлення**
```
Шлях: HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU
Ключ: AUOptions
Значення: 2 (Тільки повідомлення для завантаження)
```

### Команди для вручну модифікації:

```batch
REM Модифікація реєстру через reg.exe
reg add "HKLM\SYSTEM\CurrentControlSet\Services\wuauserv" /v Start /t REG_DWORD /d 4 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 1 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v AUOptions /t REG_DWORD /d 2 /f
```

---

## Запланові завдання

### Завдання які деактивуються:

```
📋 Microsoft\Windows\UpdateOrchestrator\Regular Maintenance
   └─ Запускає звичайне оновлення

📋 Microsoft\Windows\UpdateOrchestrator\Reboot
   └─ Перезавантажує ПК для завершення оновлень

📋 Microsoft\Windows\UpdateOrchestrator\Schedule Scan
   └─ Сканує наявність оновлень

📋 Microsoft\Windows\Update\Scheduled Start
   └─ Запускає Windows Update за розписом
```

### Команди для вручну деактивації:

```batch
REM Перегляд завдань
schtasks /query /tn "Microsoft\Windows\UpdateOrchestrator\*"
schtasks /query /tn "Microsoft\Windows\Update\*"

REM Деактивація завдань
schtasks /change /tn "Microsoft\Windows\UpdateOrchestrator\Regular Maintenance" /disable
schtasks /change /tn "Microsoft\Windows\Update\Scheduled Start" /disable
```

---

## Вирішення проблем

### ❌ Проблема: "Access Denied"

**Рішення:**
1. Запустіть скрипт від адміністратора
2. Зупиніть антивірус (тимчасово)
3. Завантажте у Safe Mode і запустіть звідти

```batch
REM Перевірка прав адміністратора
net session >nul 2>&1
if %errorlevel% neq 0 echo Запустіть від адміністратора
```

### ❌ Проблема: Скрипт не запускається

**Рішення для PowerShell:**
```powershell
REM Дозвіл на виконання скриптів
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

REM Запуск скрипту
powershell -ExecutionPolicy Bypass -File "Disable-WindowsUpdates.ps1"
```

### ❌ Проблема: Оновлення все ще встановлюються

**Рішення:**
1. Перезавантажте ПК (критично!)
2. Перевіріть, чи служба дійсно відключена: `sc query wuauserv`
3. Запустіть скрипт ще раз від адміністратора

### ❌ Проблема: Хочу скасувати операцію

**Рішення:**
```batch
REM Запустіть enable скрипт
enable_windows_updates.bat

REM АБО відновіть систему:
REM 1. Система (System) → Захист системи (System Protection)
REM 2. Відновлення системи (System Restore)
REM 3. Виберіть точку перед "Before disabling Windows Updates"
```

---

## Безпека

### ⚠️ Ризики вимикання оновлень:

| Ризик | Рівень | Опис |
|-------|--------|------|
| **Вразливості безпеки** | 🔴 Високий | Без оновлень ваша система вразлива для нових атак |
| **Відсутність патчів** | 🔴 Високий | Не отримаєте критичні виправлення |
| **Несумісність** | 🟡 Середній | Деякі програми можуть не працювати без нових обновлень |
| **Нестабільність** | 🟡 Середній | Можливі проблеми з продуктивністю |

### ✅ Як зберегти безпеку:

1. **Регулярно оновлюйте вручну** - щомісяця запускайте enable скрипт
2. **Користуйтеся антивірусом** - ESET, Kaspersky, або вбудованим Defender
3. **Фаєрвол включений** - переконайтеся що Windows Firewall активний
4. **Критичні оновлення** - отримуйте принаймні критичні патчи безпеки

### 🔐 Рекомендовані параметри:

```
Для максимальної безпеки використовуйте:
- Enable-WindowsUpdates (щомісяця)
- Запустіть Windows Update вручну
- Перезавантажте коли потрібно
- Потім знову Disable-WindowsUpdates
```

---

## 📝 Процес відновлення

Якщо щось пішло не так:

### Метод 1: Scripts (Найпростіше)
```batch
enable_windows_updates.bat
REM Перезавантажте ПК
```

### Метод 2: System Restore Point (Найнадійніше)
1. Натисніть `Win + R` і введіть `rstrui.exe`
2. Нажміть "Далі"
3. Виберіть точку "Before disabling Windows Updates"
4. Нажміть "Далі" і "Готово"
5. Перезавантажте ПК

### Метод 3: Manual Registry Edit (Для фахівців)
```batch
REM Ручне відновлення реєстру
reg add "HKLM\SYSTEM\CurrentControlSet\Services\wuauserv" /v Start /t REG_DWORD /d 2 /f
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate /t REG_DWORD /d 0 /f

REM Перезавантажте ПК
shutdown -r -t 0
```

---

## 🔍 Перевірка статусу

### Команди для перевірки:

```batch
REM Перевірити статус служб
sc query wuauserv
sc query bits
sc query DoSvc
sc query UsoSvc

REM Перевірити тип запуску
sc qc wuauserv
sc qc bits

REM Перегляд реєстру
reg query "HKLM\SYSTEM\CurrentControlSet\Services\wuauserv" /v Start
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v NoAutoUpdate

REM Перегляд завдань
schtasks /query /tn "Microsoft\Windows\UpdateOrchestrator\*"
```

---

## 📚 Корисні посилання

- Microsoft Windows Update Services: https://docs.microsoft.com/en-us/windows/win32/wua_sdk/portal
- Group Policy Editor: https://docs.microsoft.com/en-us/windows/win32/wua_sdk/group-policy
- PowerShell Docs: https://docs.microsoft.com/en-us/powershell/

---

**Версія:** 1.0  
**Дата останнього оновлення:** 2026-03-06  
**Статус:** ✅ Розроблено для Windows 10/11
