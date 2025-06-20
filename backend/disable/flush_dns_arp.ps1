# Admin check
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltinRole] "Administrator")) {
    Write-Warning "You need to run this script as Administrator."
    exit
}

Write-Output "Flushing DNS cache..."
ipconfig /flushdns | Out-Null
Write-Output "✅ DNS cache flushed."

Write-Output "Flushing ARP cache..."
netsh interface ip delete arpcache | Out-Null
Write-Output "✅ ARP cache flushed."

Write-Output "`nDone. Your network stack is squeaky clean."
