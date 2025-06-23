# Enable Balanced power plan if not already present
$balancedPlan = "381b4222-f694-41f0-9685-ff5bb260df2e"  # Balanced GUID

# Check if Balanced plan exists
$planExists = powercfg /L | Select-String $balancedPlan

if (-not $planExists) {
    Write-Output "Balanced plan not found. Adding it..."
    powercfg -duplicatescheme $balancedPlan
}

# Set Balanced plan as active
powercfg -setactive $balancedPlan

Write-Output "Balanced power plan activated to undo Ultimate Performance plan."
