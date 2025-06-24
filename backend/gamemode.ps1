# Force Game Mode always on (for future builds where this applies)
$regPath2 = "HKCU:\Software\Microsoft\GameConfigStore"
$name2 = "GameDVR_Enabled"

If (-not (Test-Path $regPath2)) {
    New-Item -Path $regPath2 -Force | Out-Null
}

Set-ItemProperty -Path $regPath2 -Name $name2 -Value 1 -Type DWord

Write-Host "🧠 GameDVR/Game Mode settings patched." -ForegroundColor Yellow
