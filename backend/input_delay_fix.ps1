# Disable HPET (High Precision Event Timer)
Write-Host "Disabling HPET..."
bcdedit /deletevalue useplatformclock

# OPTIONAL: Enable HPET again (uncomment if needed)
# bcdedit /set useplatformclock true

# Registry Tweak: Disable Mouse Acceleration
Write-Host "Disabling mouse acceleration..." -ForegroundColor Cyan
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0"
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0"
Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0"

Write-Host "🔁 Restart your PC for changes to take effect."
