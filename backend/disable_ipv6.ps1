# Admin check
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Warning "You need to run this script as Administrator."
    exit
}

Write-Output "Disabling offloads (LSO, EEE, RSS, Checksum Offload)..."

$offloadSettings = @(
    "Large Send Offload V2 (IPv4)",
    "Large Send Offload V2 (IPv6)",
    "Energy Efficient Ethernet",
    "Receive Side Scaling",
    "TCP Checksum Offload (IPv4)",
    "TCP Checksum Offload (IPv6)",
    "UDP Checksum Offload (IPv4)",
    "UDP Checksum Offload (IPv6)"
)

# Get all UP interfaces
$interfaces = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

foreach ($intf in $interfaces) {
    Write-Output "nInterface: $($intf.Name)"
    foreach ($setting in $offloadSettings) {
        try {
            Set-NetAdapterAdvancedProperty -Name $intf.Name -DisplayName $setting -DisplayValue "Disabled" -ErrorAction Stop
            Write-Output "✅ Disabled: $setting"
        } catch {
            Write-Warning "❌ Could not disable: $setting"
        }
    }
}

Write-Output "nAll possible offloads disabled (or already off). Reboot if issues persist."