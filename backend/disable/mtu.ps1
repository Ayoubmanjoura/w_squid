# Check for admin rights
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Warning "You need to run this script as Administrator."
    exit
}

Write-Output "Setting MTU to 1472 on all active interfaces..."

# Get all UP interfaces
$interfaces = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

foreach ($intf in $interfaces) {
    try {
        netsh interface ipv4 set subinterface "$($intf.Name)" mtu=1472 store=persistent
        Write-Output "✅ MTU set to 1472 on $($intf.Name)"
    } catch {
        Write-Warning "❌ Failed to set MTU on $($intf.Name)"
    }
}

Write-Output "`nDone. You may need to restart your network connection for changes to fully apply."
