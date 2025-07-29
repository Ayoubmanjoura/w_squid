# Disable-WindowsVisualEffects.ps1
# This script disables Windows visual effects to improve performance

# Requires administrative privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires administrator privileges. Please run PowerShell as Administrator."
    exit 1
}

# Import the required Win32 API functions
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class Win32 {
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int SystemParametersInfo(int uAction, int uParam, IntPtr lpvParam, int fuWinIni);
}
"@

# Visual effects to disable (corresponds to SPI_SETUIEFFECTS)
$SPI_SETUIEFFECTS = 0x103F

# Disable visual effects
Write-Host "Disabling Windows visual effects..."
[Win32]::SystemParametersInfo($SPI_SETUIEFFECTS, 0, [IntPtr]::Zero, 0) | Out-Null

# Additional registry tweaks for performance
Write-Host "Applying performance optimizations..."

# Disable animations
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0" -Force

# Disable window shadows
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ListviewShadow" -Value 0 -Force

# Disable menu animations
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Force

# Disable fade effects
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "DragFullWindows" -Value "0" -Force
Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0" -Force

# Disable Aero Peek
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "EnableAeroPeek" -Value 0 -Force

# Set performance options to "Adjust for best performance"
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Force

Write-Host "Visual effects have been disabled for better performance."
Write-Host "You may need to log off and back on for all changes to take effect."