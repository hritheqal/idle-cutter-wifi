
# 🔋 WiFi Idle Manager

A lightweight PowerShell script that automatically disconnects your WiFi when your laptop is idle and reconnects it the moment you're active again — saving battery when you forget your charger.

Built for Windows 10/11. No installs required.

---

## 💡 Problem

Low battery + no charger = need to conserve power fast.
WiFi is one of the biggest battery drains even when you're not actively using it.

---

## ✅ Solution

This script monitors your keyboard and mouse activity. If no activity is detected for a set period, it automatically disables your WiFi adapter. The moment you move your mouse or press a key, WiFi is re-enabled instantly.

---

## ⚙️ How It Works

```
Script Starts
     ↓
Monitor mouse/keyboard idle time
     ↓
Idle > 1 minute?
  ├── No  → keep checking every 30 seconds
  └── Yes → Disable WiFi + show notification
               ↓
          Wait for activity
               ↓
          Activity detected → Re-enable WiFi + show notification
```

---

## 🚀 How to Run

1. Clone or download this repo
2. Open PowerShell and navigate to the project folder:
   ```powershell
   cd path\to\wifi-idle-manager
   ```
3. Run the script:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\wifi-idle-manager.ps1
   ```
4. A UAC prompt will appear — click **Yes** (Admin required to control network adapters)

---

## 🛠️ Configuration

Open `wifi-idle-manager.ps1` and edit the top section:

```powershell
$idleThresholdMinutes = 1       # Disconnect WiFi after X minutes of idle
$checkIntervalSeconds = 30      # How often to check activity (in seconds)
$wifiAdapterName      = "Wi-Fi" # Your WiFi adapter name
```

> To find your adapter name, run: `Get-NetAdapter` in PowerShell

---

## 📋 Requirements

- Windows 10 or 11
- PowerShell 5.1+ (built-in on Windows)
- Administrator privileges (script auto-elevates)

---

## 🛑 Stop the Script

Press `Ctrl + C` in the PowerShell window.

---

## 📁 Project Structure

```
wifi-idle-manager/
└── wifi-idle-manager.ps1   # Main script
└── README.md               # This file
```

---

