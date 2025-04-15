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

5. Scoop Installer with Default Buckets
   - Installs Scoop package manager and adds main, extras, nonportable, games, and nerd-fonts buckets
   - Enables CLI package management with extended repositories

Enter numbers (1-5) separated by commas (no spaces):
"@

    $choice = Read-Host "Selection"
    $valid = $choice -match '^([1-5],)*[1-5]$'
} while (!$valid)

# Execution
$scripts = @{
    "1" = 'irm https://christitus.com/win | iex'
    "2" = 'irm https://get.activated.win | iex'
    "4" = 'Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString(''https://community.chocolatey.org/install.ps1''))'
}

$choice.Split(',') | ForEach-Object {
    Write-Host "Executing script $_..." -ForegroundColor Cyan
    if ($_ -eq "3") {
        # Winget installation using winget-install method
        try {
            Write-Host "Installing Winget via PowerShell Gallery..." -ForegroundColor Cyan
            $currentPolicy = Get-ExecutionPolicy
            if ($currentPolicy -eq "Restricted") {
                Write-Host "Temporarily setting execution policy..." -ForegroundColor Yellow
                Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            }
            
            Write-Host "Installing winget-install module..." -ForegroundColor Yellow
            Install-Script -Name winget-install -Force -Scope CurrentUser -ErrorAction Stop
            Import-Module "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\winget-install" -ErrorAction Stop
            
            Write-Host "Executing winget installation..." -ForegroundColor Yellow
            winget-install -Force -ErrorAction Stop
            
            if ($currentPolicy -eq "Restricted") {
                Write-Host "Restoring original execution policy..." -ForegroundColor Yellow
                Set-ExecutionPolicy Restricted -Scope CurrentUser -Force
            }
            
            Write-Host "Winget installation completed successfully." -ForegroundColor Green
        } catch {
            Write-Error "Winget installation failed: $($_.Exception.Message)"
            exit 1
        }
    } elseif ($_ -eq "5") {
        # Run Scoop installation as the current user (not admin)
        Write-Host "Installing Scoop as regular user..." -ForegroundColor Cyan
        
        # Get current user for the non-elevated process
        $currentUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        
        # Create a script block for Scoop installation
        $scoopScript = @'
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        irm get.scoop.sh -useb | iex
        scoop bucket add main
        scoop bucket add extras
        scoop bucket add nonportable
        scoop bucket add games
        scoop bucket add nerd-fonts
        Write-Host "Scoop installation completed successfully." -ForegroundColor Green
'@
        
        # Save to temp file
        $tempFile = [System.IO.Path]::GetTempFileName() + ".ps1"
        $scoopScript | Out-File -FilePath $tempFile -Encoding UTF8
        
        # Start a non-elevated PowerShell process as the current user
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempFile`"" -Wait
        
        # Clean up temp file
        Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
    } else {
        Invoke-Expression $scripts[$_]
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