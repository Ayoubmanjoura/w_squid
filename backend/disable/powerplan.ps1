# Enable Ultimate Performance Plan if not already present
$ultimatePlan = "e9a42b02-d5df-448d-aa00-03f14749eb61"
$planExists = powercfg /L | Select-String $ultimatePlan

if (-not $planExists) {
    Write-Output "Ultimate Performance plan not found. Adding it..."
    powercfg -duplicatescheme $ultimatePlan
}

# Set it as active
powercfg -setactive $ultimatePlan

Write-Output "Ultimate Performance plan activated for max FPS."
