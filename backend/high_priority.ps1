#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Optimize selected applications for high CPU priority and high performance graphics.
.DESCRIPTION
    Lets you pick EXE files and applies registry tweaks to:
    - Set CPU priority to High
    - Set I/O priority to High
    - Set graphics performance preference to High Performance GPU
    - Optimize memory priority and disable CPU throttling for those apps
.NOTES
    Run as Administrator.
    Compatible with Windows 10 and 11.
#>

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Check admin
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Run this script as Administrator! Exiting..."
    exit 1
}

Write-Host "Application Priority & Performance Optimizer" -ForegroundColor Green
Write-Host ("=" * 50)

function Select-Applications {
    Write-Host "`nOpening file explorer to select EXE files..." -ForegroundColor Yellow
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = "Select Applications to Optimize"
    $dialog.Filter = "Executable Files (*.exe)|*.exe|All Files (*.*)|*.*"
    $dialog.Multiselect = $true
    $dialog.InitialDirectory = [Environment]::GetFolderPath("ProgramFiles")
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        return $dialog.FileNames
    } else {
        Write-Host "No files selected. Exiting..." -ForegroundColor Red
        exit 0
    }
}

function Set-CPUPriority {
    param([string]$AppPath)
    try {
        $appName = [System.IO.Path]::GetFileName($AppPath)
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$appName\PerfOptions"

        if (-not (Test-Path $regPath)) {
            New-Item -Path $regPath -Force | Out-Null
        }

        # Set CPU priority to High (3), I/O priority to High (3)
        Set-ItemProperty -Path $regPath -Name "CpuPriorityClass" -Value 3 -Type DWord
        Set-ItemProperty -Path $regPath -Name "IoPriority" -Value 3 -Type DWord

        Write-Host "  [+] CPU and I/O Priority set to HIGH for $appName" -ForegroundColor Green
        return $true
    } catch {
        Write-Warning "  [-] Failed to set CPU priority for $appName $_"
        return $false
    }
}

function Set-GraphicsPerformance {
    param([string]$AppPath)
    try {
        $graphicsRegUser = "HKCU:\Software\Microsoft\DirectX\UserGpuPreferences"
        $graphicsRegSystem = "HKLM:\SOFTWARE\Microsoft\DirectX\UserGpuPreferences"

        if (-not (Test-Path $graphicsRegUser)) { New-Item -Path $graphicsRegUser -Force | Out-Null }
        if (-not (Test-Path $graphicsRegSystem)) { New-Item -Path $graphicsRegSystem -Force | Out-Null }

        Set-ItemProperty -Path $graphicsRegUser -Name $AppPath -Value "GpuPreference=2;" -Type String
        Set-ItemProperty -Path $graphicsRegSystem -Name $AppPath -Value "GpuPreference=2;" -Type String

        Write-Host "  [+] Graphics Performance set to HIGH for $([System.IO.Path]::GetFileName($AppPath))" -ForegroundColor Green
        return $true
    } catch {
        Write-Warning "  [-] Failed to set graphics performance: $_"
        return $false
    }
}

function Set-AdditionalOptimizations {
    param([string]$AppPath)
    try {
        $appName = [System.IO.Path]::GetFileName($AppPath)
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$appName\PerfOptions"

        if (-not (Test-Path $regPath)) { New-Item -Path $regPath -Force | Out-Null }

        # Memory priority to High (5), disable CPU throttling (0), enable large pages (1)
        Set-ItemProperty -Path $regPath -Name "PagePriority" -Value 5 -Type DWord
        Set-ItemProperty -Path $regPath -Name "CpuThrottling" -Value 0 -Type DWord
        Set-ItemProperty -Path $regPath -Name "UseLargePages" -Value 1 -Type DWord

        Write-Host "  [+] Additional performance optimizations applied for $appName" -ForegroundColor Green
        return $true
    } catch {
        Write-Warning "  [-] Failed additional optimizations: $_"
        return $false
    }
}

function Show-ConfirmationDialog {
    param([string[]]$SelectedFiles)

    $message = "The following applications will be optimized:`n`n"
    foreach ($file in $SelectedFiles) {
        $message += "• " + [System.IO.Path]::GetFileName($file) + "`n"
    }
    $message += "`nOptimizations include:`n"
    $message += "- High CPU Priority (Always)`n"
    $message += "- High I/O Priority`n"
    $message += "- High Graphics Performance`n"
    $message += "- Memory Priority Optimization`n"
    $message += "- Disabled CPU Throttling`n`n"
    $message += "Do you want to proceed?"

    $result = [System.Windows.Forms.MessageBox]::Show(
        $message,
        "Confirm Application Optimization",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )

    return $result -eq [System.Windows.Forms.DialogResult]::Yes
}

function New-RegistryBackup {
    try {
        $backupPath = "$env:TEMP\AppOptimizer_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
        $regKeys = @(
            "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options",
            "HKEY_CURRENT_USER\Software\Microsoft\DirectX\UserGpuPreferences"
        )

        foreach ($key in $regKeys) {
            reg export $key $backupPath /y 2>$null
        }

        Write-Host "Registry backup created: $backupPath" -ForegroundColor Cyan
        return $backupPath
    } catch {
        Write-Warning "Failed to create registry backup: $_"
        return $null
    }
}

# Main
try {
    $apps = Select-Applications

    if ($apps.Count -eq 0) {
        Write-Host "No applications selected. Exiting..." -ForegroundColor Red
        exit 0
    }

    Write-Host "`nSelected applications:" -ForegroundColor Cyan
    foreach ($app in $apps) { Write-Host " • " + [System.IO.Path]::GetFileName($app) }

    if (-not (Show-ConfirmationDialog -SelectedFiles $apps)) {
        Write-Host "`nOperation cancelled." -ForegroundColor Yellow
        exit 0
    }

    Write-Host "`nBacking up registry..." -ForegroundColor Yellow
    $backup = New-RegistryBackup

    Write-Host "`nApplying optimizations..." -ForegroundColor Yellow
    $successCount = 0
    $total = $apps.Count

    foreach ($app in $apps) {
        $name = [System.IO.Path]::GetFileName($app)
        Write-Host "`nProcessing: $name" -ForegroundColor Cyan

        $cpu = Set-CPUPriority -AppPath $app
        $gfx = Set-GraphicsPerformance -AppPath $app
        $opt = Set-AdditionalOptimizations -AppPath $app

        if ($cpu -and $gfx -and $opt) {
            $successCount++
            Write-Host "  [+] Optimizations applied successfully!" -ForegroundColor Green
        }
    }

    Write-Host "`n" + ("=" * 50)
    Write-Host "Summary: Optimized $successCount of $total applications" -ForegroundColor Green

    if ($backup) { Write-Host "Backup saved to: $backup" -ForegroundColor Cyan }

    Write-Host "Notes:" -ForegroundColor Yellow
    Write-Host " • Settings apply to new launches immediately."
    Write-Host " • High priority settings persist after reboot."
    Write-Host " • Restart apps to see graphics preference changes."
    Write-Host " • Use backup to restore registry if needed."

    $restart = Read-Host "`nRestart graphics drivers now? (y/N)"
    if ($restart -match '^[Yy]$') {
        Write-Host "Restarting graphics drivers..." -ForegroundColor Yellow
        try {
            Get-PnpDevice -Class Display | Disable-PnpDevice -Confirm:$false
            Start-Sleep -Seconds 2
            Get-PnpDevice -Class Display | Enable-PnpDevice -Confirm:$false
            Write-Host "Graphics drivers restarted successfully!" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to restart graphics drivers. Please restart manually if needed."
        }
    }

    Write-Host "`nAll done! Press Enter to exit."
    Read-Host
} catch {
    Write-Error "Fatal error: $_"
    exit 1
}
