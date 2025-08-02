# Disable Core Isolation Memory Integrity (HVCI)
Write-Host "Disabling Core Isolation Memory Integrity..." 

# Set registry key to disable HVCI
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name "EnableVirtualizationBasedSecurity" -PropertyType DWORD -Value 0 -Force | Out-Null

New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Force | Out-Null
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Name "Enabled" -PropertyType DWORD -Value 0 -Force | Out-Null

# Disable Secure Launch (optional – makes sure it's OFF)
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name "RequirePlatformSecurityFeatures" -PropertyType DWORD -Value 0 -Force | Out-Null

Write-Host "✅ Core Isolation (Memory Integrity) is now disabled."
Write-Host "🔁 Please reboot your PC for changes to fully take effect."
