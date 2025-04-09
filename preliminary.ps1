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

Enter numbers (1-3) separated by commas (no spaces):
"@

    $choice = Read-Host "Selection"
    $valid = $choice -match '^([1-3],)*[1-3]$'
} while (!$valid)

# Execution
$scripts = @{
    "1" = 'irm https://christitus.com/win | iex'
    "2" = 'irm https://get.activated.win | iex'
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
    } else {
        Invoke-Expression $scripts[$_]
    }
}
