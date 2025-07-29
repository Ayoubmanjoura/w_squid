# Set-FastestDNS.ps1
# Tests Google and Cloudflare DNS servers and configures the fastest one

# Requires admin privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script requires administrator privileges. Please run PowerShell as Administrator."
    exit 1
}

function Test-DNSSpeed {
    param (
        [string]$DNSAddress,
        [string]$TestDomain = "google.com"
    )
    
    $ping = New-Object System.Net.NetworkInformation.Ping
    $times = @()
    
    # Test 4 times and take average
    for ($i = 0; $i -lt 4; $i++) {
        try {
            $reply = $ping.Send($DNSAddress, 1000) # 1 second timeout
            if ($reply.Status -eq "Success") {
                $times += $reply.RoundtripTime
            }
        } catch {
            return [int]::MaxValue # Return very high value if failed
        }
    }
    
    if ($times.Count -eq 0) { return [int]::MaxValue }
    return ($times | Measure-Object -Average).Average
}

# Test DNS servers
Write-Host "Testing DNS server response times..."
$googleSpeed = Test-DNSSpeed -DNSAddress "8.8.8.8"
$cloudflareSpeed = Test-DNSSpeed -DNSAddress "1.1.1.1"

Write-Host "Google DNS (8.8.8.8) average response: $googleSpeed ms"
Write-Host "Cloudflare DNS (1.1.1.1) average response: $cloudflareSpeed ms"

# Determine fastest DNS
if ($googleSpeed -lt $cloudflareSpeed) {
    $primaryDNS = "8.8.8.8"
    $secondaryDNS = "8.8.4.4"
    $provider = "Google"
} else {
    $primaryDNS = "1.1.1.1"
    $secondaryDNS = "1.0.0.1"
    $provider = "Cloudflare"
}

# Get all active network interfaces
$interfaces = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }

foreach ($interface in $interfaces) {
    # Skip loopback and tunnel interfaces
    if ($interface.InterfaceDescription -match "Loopback|Tunnel|Virtual") { continue }
    
    Write-Host "Configuring $($interface.Name) with $provider DNS ($primaryDNS, $secondaryDNS)"
    
    # Set DNS servers
    Set-DnsClientServerAddress -InterfaceIndex $interface.InterfaceIndex `
        -ServerAddresses ($primaryDNS, $secondaryDNS)
}

Write-Host "`nDNS configuration complete. Using $provider DNS servers:"
Write-Host "Primary: $primaryDNS"
Write-Host "Secondary: $secondaryDNS"
Write-Host "`nNote: You may need to restart your applications for changes to take effect."