# Disable-NagleAlgorithm.ps1
# This script disables Nagle's algorithm by setting TCPNoDelay to 1 in the registry

# Requires administrative privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires administrator privileges. Please run PowerShell as Administrator."
    exit 1
}

# Registry path for TCP/IP parameters
$registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"

# Get all network interfaces
$interfaces = Get-ChildItem -Path $registryPath

# Counter for modified interfaces
$modifiedCount = 0

foreach ($interface in $interfaces) {
    # Check if TCPNoDelay value exists
    $tcpNoDelay = Get-ItemProperty -Path $interface.PSPath -Name "TCPNoDelay" -ErrorAction SilentlyContinue
    
    if ($null -eq $tcpNoDelay) {
        # Create the value if it doesn't exist
        New-ItemProperty -Path $interface.PSPath -Name "TCPNoDelay" -Value 1 -PropertyType DWORD -Force | Out-Null
        Write-Host "Disabled Nagle's algorithm for interface $($interface.PSChildName)"
        $modifiedCount++
    }
    elseif ($tcpNoDelay.TCPNoDelay -ne 1) {
        # Update the value if it's not already set to 1
        Set-ItemProperty -Path $interface.PSPath -Name "TCPNoDelay" -Value 1 | Out-Null
        Write-Host "Disabled Nagle's algorithm for interface $($interface.PSChildName)"
        $modifiedCount++
    }
}

if ($modifiedCount -eq 0) {
    Write-Host "Nagle's algorithm was already disabled on all interfaces."
}
else {
    Write-Host "Nagle's algorithm has been disabled on $modifiedCount interface(s)."
}

Write-Host "Note: A system restart may be required for changes to take effect."