# ============================================================
# wifi-idle-manager.ps1
# Auto-disconnects WiFi after a period of inactivity,
# and reconnects when activity is detected.
# ============================================================

# --- Require Administrator ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Restarting as Administrator..." -ForegroundColor Yellow
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# --- CONFIGURATION ---
$idleThresholdMinutes = 1       # Disconnect WiFi after this many minutes of idle
$checkIntervalSeconds = 30      # How often to check for idle (in seconds)
$wifiAdapterName      = "Wi-Fi" # Change this if your adapter has a different name
# ---------------------

# Load Win32 API to read last user input time
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class UserActivity {
    [StructLayout(LayoutKind.Sequential)]
    public struct LASTINPUTINFO {
        public uint cbSize;
        public uint dwTime;
    }

    [DllImport("user32.dll")]
    public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);

    public static uint GetIdleMilliseconds() {
        LASTINPUTINFO info = new LASTINPUTINFO();
        info.cbSize = (uint)Marshal.SizeOf(info);
        GetLastInputInfo(ref info);
        return (uint)Environment.TickCount - info.dwTime;
    }
}
"@

function Get-IdleMinutes {
    $idleMs = [UserActivity]::GetIdleMilliseconds()
    return [math]::Round($idleMs / 60000, 2)
}

function Get-WifiStatus {
    $adapter = Get-NetAdapter -Name $wifiAdapterName -ErrorAction SilentlyContinue
    if ($null -eq $adapter) { return "NOT_FOUND" }
    return $adapter.Status  # "Up" or "Disabled"
}

function Disable-Wifi {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Disabling WiFi (idle for $idleMinutes min)..." -ForegroundColor Yellow
    Disable-NetAdapter -Name $wifiAdapterName -Confirm:$false
    Show-Notification "WiFi Disconnected" "No activity detected for $idleThresholdMinutes min. WiFi disabled to save battery."
}

function Enable-Wifi {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Activity detected! Re-enabling WiFi..." -ForegroundColor Green
    Enable-NetAdapter -Name $wifiAdapterName -Confirm:$false
    Show-Notification "WiFi Reconnected" "Activity detected. WiFi has been re-enabled."
}

function Show-Notification($title, $message) {
    Add-Type -AssemblyName System.Windows.Forms
    $notify = New-Object System.Windows.Forms.NotifyIcon
    $notify.Icon = [System.Drawing.SystemIcons]::Information
    $notify.Visible = $true
    $notify.ShowBalloonTip(4000, $title, $message, [System.Windows.Forms.ToolTipIcon]::Info)
    Start-Sleep -Seconds 1
    $notify.Dispose()
}

# --- MAIN LOOP ---
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "  WiFi Idle Manager Started" -ForegroundColor Cyan
Write-Host "  Idle threshold : $idleThresholdMinutes minute(s)" -ForegroundColor Cyan
Write-Host "  Check interval : $checkIntervalSeconds second(s)" -ForegroundColor Cyan
Write-Host "  WiFi adapter   : $wifiAdapterName" -ForegroundColor Cyan
Write-Host "  Press Ctrl+C to stop." -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$wifiWasDisabled = $false

while ($true) {
    $idleMinutes = Get-IdleMinutes
    $wifiStatus  = Get-WifiStatus

    if ($wifiStatus -eq "NOT_FOUND") {
        Write-Host "[ERROR] WiFi adapter '$wifiAdapterName' not found. Check the name and try again." -ForegroundColor Red
        Write-Host "Available adapters:" -ForegroundColor Yellow
        Get-NetAdapter | Select-Object Name, Status | Format-Table -AutoSize
        exit 1
    }

    if (-not $wifiWasDisabled -and $idleMinutes -ge $idleThresholdMinutes) {
        Disable-Wifi
        $wifiWasDisabled = $true
    }
    elseif ($wifiWasDisabled -and $idleMinutes -lt 1) {
        Enable-Wifi
        $wifiWasDisabled = $false
    }
    else {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Idle: $idleMinutes min | WiFi: $wifiStatus" -ForegroundColor DarkGray
    }

    Start-Sleep -Seconds $checkIntervalSeconds
}
