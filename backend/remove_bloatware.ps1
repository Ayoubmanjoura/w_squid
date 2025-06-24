# Remove Bloatware from Windows 
$appList = @(
    "Microsoft.3DBuilder",
    "Microsoft.XboxApp",
    "Microsoft.XboxGameOverlay",
    "Microsoft.XboxGamingOverlay",
    "Microsoft.XboxIdentityProvider",
    "Microsoft.XboxSpeechToTextOverlay",
    "Microsoft.ZuneMusic",
    "Microsoft.ZuneVideo",
    "Microsoft.GetHelp",
    "Microsoft.Messaging",
    "Microsoft.Microsoft3DViewer",
    "Microsoft.MixedReality.Portal",
    "Microsoft.MicrosoftSolitaireCollection",
    "Microsoft.SkypeApp",
    "Microsoft.People",
    "Microsoft.OneConnect",
    "Microsoft.Wallet",
    "Microsoft.Office.OneNote",
    "Microsoft.BingNews",
    "Microsoft.BingWeather",
    "Microsoft.Todos",
    "Microsoft.MicrosoftStickyNotes",
    "Microsoft.YourPhone",
    "Microsoft.PowerAutomateDesktop",
    "MicrosoftTeams",
    "Microsoft.WindowsAlarms",
    "Microsoft.WindowsFeedbackHub",
    "Microsoft.WindowsMaps"
    # MS Paint is NOT removed. You're welcome.
)

foreach ($app in $appList) {
    Write-Host "Removing $app..." -ForegroundColor Yellow
    Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
    Get-AppxProvisionedPackage -Online | Where-Object {$_.DisplayName -eq $app} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
}
Write-Host "`nDone. Reboot for full effect." -ForegroundColor Green
