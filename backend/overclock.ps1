# Smart Overclocker PS1 - only tweaks if CPU is unlocked

# --- FUNCTIONS ---

function Is-CPUUnlockable {
    param([string]$cpuName)
    # Basic heuristic: Intel K-series or AMD Ryzen are unlockable
    if ($cpuName -match "K$" -or $cpuName -match "Ryzen") {
        return $true
    }
    return $false
}

function Get-BaseClock {
    # Windows doesn't expose BCLK directly, assume default 100MHz for Intel/AMD
    return 100
}

function Get-CurrentMultiplier {
    # Approximate multiplier = Current Clock / Base Clock
    $cpu = Get-WmiObject Win32_Processor
    $currentMHz = $cpu.CurrentClockSpeed
    $baseClock = Get-BaseClock
    return [math]::Floor($currentMHz / $baseClock)
}

# --- SCRIPT START ---

$cpu = Get-WmiObject Win32_Processor
$cpuName = $cpu.Name.Trim()
Write-Host "Detected CPU: $cpuName"

$unlockable = Is-CPUUnlockable -cpuName $cpuName

if (-not $unlockable) {
    Write-Warning "This CPU is likely locked (non-K Intel or non-Ryzen). No overclocking will be applied."
    Write-Host "You can only do minimal BCLK tweaks if your motherboard supports it."
    # Optionally, prompt for small BCLK bump (e.g. 101-103)
    $userBCLK = Read-Host "Enter BCLK frequency (MHz) [Default 100]"
    if (-not [int]::TryParse($userBCLK, [ref]$null)) { $userBCLK = 100 }
    else { $userBCLK = [int]$userBCLK }

    if ($userBCLK -le 100) {
        Write-Host "No BCLK increase detected, exiting."
        exit
    }

    Write-Host "Attempting to set BCLK to $userBCLK MHz (Use with caution!)"

    # Apply BCLK change if possible - placeholder, real method depends on motherboard
    Write-Warning "BCLK adjustment usually requires BIOS or specific tools and may brick your system."
    Write-Host "No automatic adjustment performed in this script for safety."
    exit
}

# If unlockable CPU:
$baseClock = Get-BaseClock
$currentMultiplier = Get-CurrentMultiplier
$currentFreq = $baseClock * $currentMultiplier

Write-Host "Base Clock (BCLK): $baseClock MHz"
Write-Host "Current Multiplier: $currentMultiplier"
Write-Host "Current CPU Frequency: $currentFreq MHz"

# Get target multiplier from user with defaults
$targetMultiplierInput = Read-Host "Enter target multiplier (Current: $currentMultiplier)"
if (-not [int]::TryParse($targetMultiplierInput, [ref]$null)) {
    $targetMultiplier = $currentMultiplier
} else {
    $targetMultiplier = [int]$targetMultiplierInput
}

if ($targetMultiplier -lt $currentMultiplier) {
    Write-Warning "Target multiplier is lower than current. No overclocking applied."
    exit
}

$targetFreq = $baseClock * $targetMultiplier
Write-Host "Target CPU Frequency will be $targetFreq MHz"

# Voltage (Vcore) adjustment (safe default for air cooling)
$defaultVcore = 1.25
$vcoreInput = Read-Host "Enter target Vcore voltage in Volts (default: $defaultVcore)"
if (-not [double]::TryParse($vcoreInput, [ref]$null)) {
    $targetVcore = $defaultVcore
} else {
    $targetVcore = [double]$vcoreInput
}
if ($targetVcore -gt 1.4) {
    Write-Warning "Voltage above 1.4V may damage your CPU. Proceed with caution."
}

Write-Host "`nApplying overclock settings..."

# Check for Intel XTU CLI (adjust paths as needed)
$xtuCliPath = "C:\Program Files (x86)\Intel\Intel(R) Extreme Tuning Utility\Client\XtuCli.exe"
if (-not (Test-Path $xtuCliPath)) {
    Write-Warning "Intel XTU CLI not found. Cannot apply voltage or multiplier changes automatically."
    Write-Host "Please apply these settings manually in BIOS or Intel XTU GUI."
    exit
}

# Apply voltage
& "$xtuCliPath" -t set -id 40 -v $targetVcore
Write-Host "Set Vcore voltage to $targetVcore V"

# Apply multiplier - this depends on support, usually done via BIOS or advanced tools
Write-Host "Note: Changing CPU multiplier usually requires BIOS or motherboard software."
Write-Warning "This script cannot reliably change multiplier automatically."

# Final message
Write-Host "`nOverclock setup done. Reboot your PC and test stability with stress tests."
Write-Host "Always monitor temps and voltages to avoid frying your CPU."

