#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Disables NetBIOS and SMBv1 for security hardening
.DESCRIPTION
    This script disables NetBIOS over TCP/IP and SMBv1 protocol to improve security posture.
    NetBIOS and SMBv1 are legacy protocols with known security vulnerabilities.
.NOTES
    Requires Administrator privileges
    A system restart may be required for changes to take full effect
#>

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "This script must be run as Administrator. Exiting..."
    exit 1
}

Write-Host "Starting NetBIOS and SMBv1 Disabling Process..." -ForegroundColor Green
Write-Host "=" * 50

# Function to disable NetBIOS over TCP/IP
function Disable-NetBIOS {
    Write-Host "`nDisabling NetBIOS over TCP/IP..." -ForegroundColor Yellow
    
    try {
        # Get all network adapters
        $adapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
        
        foreach ($adapter in $adapters) {
            $result = $adapter.SetTcpipNetbios(2)  # 2 = Disable NetBIOS over TCP/IP
            
            if ($result.ReturnValue -eq 0) {
                Write-Host "  ✓ NetBIOS disabled on adapter: $($adapter.Description)" -ForegroundColor Green
            } else {
                Write-Warning "  ✗ Failed to disable NetBIOS on adapter: $($adapter.Description)"
            }
        }
        
        # Additional registry method for thoroughness
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces"
        if (Test-Path $regPath) {
            Get-ChildItem $regPath | ForEach-Object {
                Set-ItemProperty -Path $_.PSPath -Name "NetbiosOptions" -Value 2 -Force
            }
            Write-Host "  ✓ NetBIOS registry settings updated" -ForegroundColor Green
        }
        
    } catch {
        Write-Error "Error disabling NetBIOS: $($_.Exception.Message)"
    }
}

# Function to disable SMBv1
function Disable-SMBv1 {
    Write-Host "`nDisabling SMBv1..." -ForegroundColor Yellow
    
    try {
        # Method 1: Using PowerShell SMB cmdlets (Windows 8/Server 2012+)
        if (Get-Command "Set-SmbServerConfiguration" -ErrorAction SilentlyContinue) {
            Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force -Confirm:$false
            Write-Host "  ✓ SMBv1 server protocol disabled" -ForegroundColor Green
            
            # Disable SMBv1 client
            if (Get-Command "Disable-WindowsOptionalFeature" -ErrorAction SilentlyContinue) {
                Disable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -NoRestart
                Write-Host "  ✓ SMBv1 client feature disabled" -ForegroundColor Green
            }
        }
        
        # Method 2: Registry method (works on all Windows versions)
        $regPaths = @(
            "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters",
            "HKLM:\SYSTEM\CurrentControlSet\Services\mrxsmb10"
        )
        
        # Disable SMBv1 server
        Set-ItemProperty -Path $regPaths[0] -Name "SMB1" -Value 0 -Force
        Write-Host "  ✓ SMBv1 server disabled via registry" -ForegroundColor Green
        
        # Disable SMBv1 client
        Set-ItemProperty -Path $regPaths[1] -Name "Start" -Value 4 -Force
        Write-Host "  ✓ SMBv1 client disabled via registry" -ForegroundColor Green
        
        # Additional SMBv1 client registry setting
        $clientRegPath = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters"
        Set-ItemProperty -Path $clientRegPath -Name "AllowInsecureGuestAuth" -Value 0 -Force
        Write-Host "  ✓ Insecure guest authentication disabled" -ForegroundColor Green
        
    } catch {
        Write-Error "Error disabling SMBv1: $($_.Exception.Message)"
    }
}

# Function to verify current status
function Get-CurrentStatus {
    Write-Host "`nCurrent Protocol Status:" -ForegroundColor Cyan
    Write-Host "-" * 25
    
    # Check NetBIOS status
    try {
        $netbiosEnabled = $false
        $adapters = Get-WmiObject -Class Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true }
        foreach ($adapter in $adapters) {
            if ($adapter.TcpipNetbiosOptions -ne 2) {
                $netbiosEnabled = $true
                break
            }
        }
        Write-Host "NetBIOS Status: $(if ($netbiosEnabled) { 'ENABLED' } else { 'DISABLED' })" -ForegroundColor $(if ($netbiosEnabled) { 'Red' } else { 'Green' })
    } catch {
        Write-Host "NetBIOS Status: Unable to determine" -ForegroundColor Yellow
    }
    
    # Check SMBv1 status
    try {
        $smbv1Status = "UNKNOWN"
        if (Get-Command "Get-SmbServerConfiguration" -ErrorAction SilentlyContinue) {
            $smbConfig = Get-SmbServerConfiguration
            $smbv1Status = if ($smbConfig.EnableSMB1Protocol) { "ENABLED" } else { "DISABLED" }
        } else {
            # Check registry for older systems
            $regValue = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "SMB1" -ErrorAction SilentlyContinue
            if ($regValue -and $regValue.SMB1 -eq 0) {
                $smbv1Status = "DISABLED"
            } else {
                $smbv1Status = "ENABLED"
            }
        }
        Write-Host "SMBv1 Status: $smbv1Status" -ForegroundColor $(if ($smbv1Status -eq 'ENABLED') { 'Red' } else { 'Green' })
    } catch {
        Write-Host "SMBv1 Status: Unable to determine" 
    }
}

# Main execution
try {
    # Show current status before changes
    Write-Host "BEFORE CHANGES:" 
    Get-CurrentStatus
    
    # Disable protocols
    Disable-NetBIOS
    Disable-SMBv1
    
    # Show status after changes
    Write-Host "`nAFTER CHANGES:"
    Get-CurrentStatus
    
    Write-Host "`n" + "=" * 50
    Write-Host "Security hardening completed successfully!"
    Write-Host "`nIMPORTANT NOTES:"
    Write-Host "• A system restart is recommended for all changes to take full effect"
    Write-Host "• SMBv1 disabling may affect older applications or network devices"
    Write-Host "• NetBIOS disabling may affect name resolution in some environments"
    Write-Host "• Test network connectivity after restart to ensure no issues"
    
    # Prompt for restart
    $restart = Read-Host "`nWould you like to restart the computer now? (y/N)"
    if ($restart -eq 'y' -or $restart -eq 'Y') {
        Write-Host "Restarting computer in 10 seconds..." 
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    }
    
} catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}