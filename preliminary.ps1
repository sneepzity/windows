# Check for administrative privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Elevating script to run as Administrator..."
    Start-Process powershell "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Script Menu
do {
    Clear-Host
    Write-Host @"
1. Chris Titus Tech Utility
   - System optimization repair script from ChrisTitusTech
   - Includes app installs cleanup and configuration

2. Microsoft Activation Script
   - Windows Office activator using HWID OHook methods
   - From Microsoft-Activation-Scripts project

3. Winget Installer
   - Silent installation of Windows Package Manager
   - Enables modern app installation via CLI

4. Chocolatey Installer
   - Silent installation of Chocolatey package manager
   - Enables package management via CLI

Enter numbers (1-4) separated by commas (no spaces):
"@

    $choice = Read-Host "Selection"
    $valid = $choice -match '^([1-4],)*[1-4]$'
} while (!$valid)

# Execution
$scripts = @{
    "1" = 'irm https://christitus.com/win | iex'
    "2" = 'irm https://get.activated.win | iex'
    "4" = 'Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString(''https://community.chocolatey.org/install.ps1''))'
}

# Sort choices to ensure winget (option 3) runs last if present
$sortedChoices = $choice.Split(',') | Sort-Object { $_ -eq "3" }

foreach ($option in $sortedChoices) {
    Write-Host "Executing script $option..." -ForegroundColor Cyan
    if ($option -eq "3") {
        # Winget installation using direct download method
        try {
            Write-Host "Installing Winget via direct download..." -ForegroundColor Cyan
            
            # Execute the winget-install script directly
            Invoke-Expression (Invoke-RestMethod -Uri "https://github.com/asheroto/winget-install/releases/latest/download/winget-install.ps1")
            
            Write-Host "Winget installation completed successfully." -ForegroundColor Green
            Write-Host "Press Enter to continue..." -ForegroundColor Yellow
            Read-Host
        } catch {
            Write-Error "Winget installation failed: $($_.Exception.Message)"
            Write-Host "Press Enter to continue..." -ForegroundColor Red
            Read-Host
        }
    } else {
        Invoke-Expression $scripts[$option]
    }
}

# Reboot prompt
$reboot = Read-Host "Do you want to reboot now? (Y/n)"
if ($reboot -eq "" -or $reboot -eq "Y" -or $reboot -eq "y") {
    Write-Host "Rebooting system..." -ForegroundColor Cyan
    Restart-Computer -Force
} else {
    Write-Host "Reboot canceled. Changes will take effect after next restart." -ForegroundColor Yellow
}