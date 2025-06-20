# Admin check
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Warning "You need to run this script as Administrator."
    exit
}

Write-Output "Enabling TCP Auto-Tuning and Congestion Control..."

# Enable auto-tuning (default level is usually 'normal')
netsh interface tcp set global autotuninglevel=normal | Out-Null
Write-Output "✅ TCP Auto-Tuning: Enabled (Normal)"

# Enable congestion control (default is usually 'ctcp' on Windows 10+, but 'none' or 'default' on some)
netsh interface tcp set global congestionprovider=ctcp | Out-Null
Write-Output "✅ Congestion Control: CTCP"

# Optional visibility
Write-Output "`nCurrent TCP settings:"
netsh interface tcp show global

Write-Output "`nDone. No reboot needed, but reconnect network to ensure effect."
