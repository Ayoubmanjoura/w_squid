$userTemp = $env:TEMP
Write-Output "Cleaning user temp folder: $userTemp"
Remove-Item -Path "$userTemp\*" -Recurse -Force -ErrorAction SilentlyContinue

$windowsTemp = "$env:WINDIR\Temp"
Write-Output "Cleaning Windows temp folder: $windowsTemp"
Remove-Item -Path "$windowsTemp\*" -Recurse -Force -ErrorAction SilentlyContinue

$profiles = Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue
foreach ($profile in $profiles) {
    $profileTemp = "$($profile.FullName)\AppData\Local\Temp"
    if (Test-Path $profileTemp) {
        Write-Output "Cleaning temp for profile: $($profile.Name)"
        Remove-Item -Path "$profileTemp\*" -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Output "Cleaning Recycle Bin..."
Clear-RecycleBin -Force -ErrorAction SilentlyContinue
Write-Output "Recycle Bin cleaned. PC is squeaky clean now."
