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
    "3" = 'irm winget.pro | iex'
}

$choice.Split(',') | ForEach-Object {
    Write-Host "Executing script $_..." -ForegroundColor Cyan
    Invoke-Expression $scripts[$_]
}