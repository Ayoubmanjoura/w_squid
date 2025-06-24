# Disable fullscreen optimizations for your user account globally
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "GameDVR_FSEBehaviorMode" -Value 1

Write-Output "Fullscreen optimizations disabled globally for the current user."
