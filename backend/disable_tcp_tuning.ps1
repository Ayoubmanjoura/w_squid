# Admin check
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Warning "You need to run this script as Administrator."
    exit
}

Write-Output "Disabling TCP Auto-Tuning and Congestion Control..."

# Disable auto-tuning
netsh interface tcp set global autotuninglevel=disabled | Out-Null
Write-Output "✅ TCP Auto-Tuning: Disabled"

# Disable congestion control
netsh interface tcp set global congestionprovider=none | Out-Null
Write-Output "✅ Congestion Control: None"

# Optional visibility (if you want to check current state)
Write-Output "`nCurrent TCP settings:"
netsh interface tcp show global

Write-Output "`nDone. A restart is not required, but reconnecting to network may help apply changes."
