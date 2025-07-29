# Disable-WindowsDeliveryOptimization.ps1
# Turns off Windows Update Delivery Optimization (peer-to-peer sharing)

# Requires admin privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires administrator privileges. Please run PowerShell as Administrator."
    exit 1
}

Write-Host "Disabling Windows Update Delivery Optimization..."

# Registry paths
$deliveryOptimizationPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization"
$dosvcPath = "HKLM:\SYSTEM\CurrentControlSet\Services\DoSvc"

# Check if Delivery Optimization service exists (but we won't modify it)
if (Test-Path $dosvcPath) {
    Write-Host "Warning: The Delivery Optimization service (DoSvc) exists, but this script will not modify services."
    Write-Host "We'll only disable the peer-to-peer functionality through registry settings."
}

# Create/update registry keys to disable Delivery Optimization
if (-not (Test-Path $deliveryOptimizationPath)) {
    New-Item -Path $deliveryOptimizationPath -Force | Out-Null
}

Set-ItemProperty -Path $deliveryOptimizationPath -Name "SystemSettingsDownloadMode" -Value 0 -Type DWord -Force
Set-ItemProperty -Path $deliveryOptimizationPath -Name "DownloadMode" -Value 0 -Type DWord -Force

# Additional settings to ensure it's fully disabled
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" -Name "DODownloadMode" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

Write-Host "Delivery Optimization has been disabled."
Write-Host "Note: Changes may take effect after the next reboot."
Write-Host "You can verify the settings in: Settings > Update & Security > Delivery Optimization"