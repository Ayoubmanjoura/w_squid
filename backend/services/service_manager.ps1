# Requires PowerShell 7+ 

$yamlPath = ".\services.yaml"

if (-Not (Test-Path $yamlPath)) {
    Write-Error "YAML file not found at $yamlPath"
    exit 1
}

$servicesToManage = Get-Content $yamlPath -Raw | ConvertFrom-Yaml

foreach ($serviceName in $servicesToManage.PSObject.Properties.Name) {
    $shouldDisable = $servicesToManage.$serviceName

    $svc = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

    if ($null -eq $svc) {
        Write-Warning "Service '$serviceName' not found."
        continue
    }

    try {
        if ($shouldDisable) {

            Write-Output "Disabling service: $serviceName"
            Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
            Set-Service -Name $serviceName -StartupType Disabled
        }
        else {

            Write-Output "Enabling service: $serviceName"
            Set-Service -Name $serviceName -StartupType Automatic
            Start-Service -Name $serviceName -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Warning "Failed to change service '$serviceName': $_"
    }
}
