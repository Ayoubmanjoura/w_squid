# Admin check
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Warning "You need to run this script as Administrator."
    exit
}

Write-Output "Enabling IPv6 on all active interfaces..."

$interfaces = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

foreach ($intf in $interfaces) {
    try {
        Enable-NetAdapterBinding -Name $intf.Name -ComponentID ms_tcpip6 -ErrorAction Stop
        Write-Output "✅ IPv6 enabled on $($intf.Name)"
    } catch {
        Write-Warning "❌ Failed to enable IPv6 on $($intf.Name)"
    }
}

Write-Output "`nDone. You may need to reboot for full effect."
