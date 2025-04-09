# PowerShell Script to Selectively Install Applications using Winget
# --- Configuration ---
$AutoInstallWinget = $true

# --- Winget Check ---
Write-Host "Checking for Winget command..." -ForegroundColor Yellow
$wingetCmd = Get-Command winget -ErrorAction SilentlyContinue

if ($null -eq $wingetCmd) {
    if ($AutoInstallWinget) {
        try {
            Write-Host "Installing Winget via PowerShell Gallery..." -ForegroundColor Cyan
            # Set execution policy if needed
            $currentPolicy = Get-ExecutionPolicy
            if ($currentPolicy -eq "Restricted") {
                Write-Host "Temporarily setting execution policy to RemoteSigned..." -ForegroundColor Yellow
                Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
            }
            
            # Install winget-install script
            Install-Script -Name winget-install -Force -Scope CurrentUser
            Import-Module "$env:USERPROFILE\Documents\WindowsPowerShell\Modules\winget-install"
            
            # Execute installation
            winget-install -Force
            
            # Restore original execution policy if needed
            if ($currentPolicy -eq "Restricted") {
                Write-Host "Restoring original execution policy..." -ForegroundColor Yellow
                Set-ExecutionPolicy Restricted -Scope CurrentUser -Force
            }
            
            # Verify installation
            $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
            if ($null -ne $wingetCmd) {
                Write-Host "Winget installed successfully." -ForegroundColor Green
            } else {
                throw "Winget installation failed"
            }
        } catch {
            Write-Error "Winget installation failed: $($_.Exception.Message)"
            exit 1
        }
    } else {
        Write-Error "Winget not found and automatic installation is disabled."
        exit 1
    }
} else {
    Write-Host "Winget found." -ForegroundColor Green
}

# --- Define App List ---
$apps = @(
    [PSCustomObject]@{Name="All Apps"; ID="SELECT_ALL"; Description="Install all available applications"}
    [PSCustomObject]@{Name="Greenshot"; ID="Greenshot.Greenshot"; Description="Screen capture tool with annotation features."}
    [PSCustomObject]@{Name="Revo Uninstaller"; ID="RevoUninstaller.RevoUninstaller"; Description="Uninstaller utility to remove programs and leftover files/registry entries."}
    [PSCustomObject]@{Name="Zen Browser"; ID="Zen-Team.Zen-Browser"; Description="Privacy-focused web browser."}
    [PSCustomObject]@{Name=".NET 6 Desktop Runtime"; ID="Microsoft.DotNet.DesktopRuntime.6"; Description="Microsoft framework required to run applications built for .NET 6."}
    [PSCustomObject]@{Name="Visual C++ Redistributable (2015+)"; ID="Microsoft.VCRedist.2015+.x64"; Description="Microsoft libraries required by many applications developed with Visual C++."}
    [PSCustomObject]@{Name="MS Edge WebView2 Runtime"; ID="Microsoft.EdgeWebView2Runtime"; Description="Embeds web content in applications using the Edge rendering engine."}
    [PSCustomObject]@{Name="Everything Search"; ID="voidtools.Everything"; Description="Instant file and folder name search tool for Windows."}
    [PSCustomObject]@{Name="EverythingToolbar"; ID="stnkl.EverythingToolbar"; Description="Integrates Everything Search into the Windows Taskbar."}
    [PSCustomObject]@{Name="Free Download Manager"; ID="SoftDeluxe.FreeDownloadManager"; Description="Download accelerator and manager."}
    [PSCustomObject]@{Name="Icaros Shell Extensions"; ID="Xanashi.Icaros"; Description="Provides Windows Explorer thumbnails for various video file types."}
    [PSCustomObject]@{Name="NanaZip"; ID="M2Team.NanaZip"; Description="Open-source file archiver (alternative to WinRAR/7-Zip)."}
    [PSCustomObject]@{Name="WizTree Disk Space Analyzer"; ID="AntibodySoftware.WizTree"; Description="Fast disk space analyzer to see what uses storage."}
    [PSCustomObject]@{Name="Flow Launcher"; ID="Flow-Launcher.Flow-Launcher"; Description="Quick application launcher and file search utility."}
    [PSCustomObject]@{Name="NextDNS Client"; ID="NextDNS.NextDNS"; Description="Official client for the NextDNS privacy & security DNS service."}
    [PSCustomObject]@{Name="Notepad++"; ID="Notepad++.Notepad++"; Description="Free source code editor and Notepad replacement."}
    [PSCustomObject]@{Name="Oracle VirtualBox"; ID="Oracle.VirtualBox"; Description="Software for creating and running virtual machines."}
    [PSCustomObject]@{Name="EarTrumpet Audio Control"; ID="File-New-Project.EarTrumpet"; Description="Advanced volume control application for Windows."}
    [PSCustomObject]@{Name="Spotify"; ID="Spotify.Spotify"; Description="Music streaming service client."}
    [PSCustomObject]@{Name="Spicetify CLI"; ID="Spicetify.SpicetifyCLI"; Description="Command-line tool to customize the official Spotify client."}
    [PSCustomObject]@{Name="YouTube Music (th-ch)"; ID="th-ch.YouTubeMusic"; Source="winget"; Description="Desktop client for YouTube Music."}
    [PSCustomObject]@{Name="AutoHotkey"; ID="AutoHotkey.AutoHotkey"; Description="Scripting language for task automation and creating hotkeys."}
    [PSCustomObject]@{Name="Playnite Game Launcher"; ID="Playnite.Playnite"; Description="Open-source launcher for managing multiple game libraries."}
    [PSCustomObject]@{Name="Vesktop (Discord Client)"; ID="Vesktop.Vesktop"; Description="Alternative Discord desktop client focused on performance/features."}
    [PSCustomObject]@{Name="Dual Monitor Tools"; ID="DualMonitorTools.DualMonitorTools"; Description="Utilities for managing multiple monitors (hotkeys, wallpaper, etc.)."}
    [PSCustomObject]@{Name="Microsoft PowerToys"; ID="Microsoft.PowerToys"; Description="Set of utilities for power users to tune Windows experience."}
    [PSCustomObject]@{Name="Rainmeter Desktop Customization"; ID="Rainmeter.Rainmeter"; Description="Tool for displaying customizable skins/widgets on the desktop."}
    [PSCustomObject]@{Name="Patch My PC Home Updater"; ID="PatchMyPC.PatchMyPC"; Description="Utility to check for and install updates for many third-party applications."}
    [PSCustomObject]@{Name="Windows Terminal"; ID="Microsoft.WindowsTerminal"; Description="Modern terminal application from Microsoft with tabs and customization."}
)

# --- Display Application Menu ---
Write-Host "--------------------------------------------------" -ForegroundColor Green
Write-Host "Available applications to install via Winget:" -ForegroundColor Green
for ($i = 0; $i -lt $apps.Count; $i++) {
    Write-Host ("[{0}] {1}" -f $i, $apps[$i].Name) -ForegroundColor White
    Write-Host ("    - {0}" -f $apps[$i].Description) -ForegroundColor Gray
}
Write-Host "--------------------------------------------------"

# --- Get User Selection ---
$userInput = $null
while ($userInput -eq $null) {
    $rawInput = Read-Host "Enter numbers (0 for all) separated by commas (e.g. 0,5,12)"
    if ($rawInput -eq '0') {
        $userInput = '0'
    } elseif ($rawInput -match '^([0-9]+,)*[0-9]+$') {
        $userInput = $rawInput
    } else {
        Write-Warning "Invalid input format. Use numbers or 0 for all."
    }
}

# --- Handle Selection ---
if ($userInput -eq '0') {
    $selectedIndices = 1..($apps.Count-1)
} else {
    $selectedIndices = $userInput -split ',' | ForEach-Object { [int]$_ }
}

# --- Prepare Logging ---
$documentsPath = [Environment]::GetFolderPath('MyDocuments')
$logFileName = "winget_install_log_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
$logFilePath = Join-Path -Path $documentsPath -ChildPath $logFileName
$ErrorOccurred = $false

try {
    Start-Transcript -Path $logFilePath -Force
    Write-Host "`n--- Installation Log Start ---"

    foreach ($selectedIndex in $selectedIndices) {
        if ($selectedIndex -ge $apps.Count) { continue }
        $app = $apps[$selectedIndex]
        if ($app.ID -eq "SELECT_ALL") { continue }

        Write-Host "--------------------------------------------------"
        Write-Host "Installing: $($app.Name) ($($app.ID))" -ForegroundColor Yellow
        
        $params = @("install", "--id", $app.ID, "--exact", "--silent", "--accept-package-agreements", "--accept-source-agreements")
        if ($app.Source) { $params += "--source", $app.Source }

        & winget $params
        $exitCode = $LASTEXITCODE

        if ($exitCode -eq 0) {
            $verifyResult = & winget list --id $app.ID --exact
            if ($verifyResult -match [regex]::Escape($app.ID)) {
                Write-Host "Verified: $($app.Name) installed successfully." -ForegroundColor Green
            } else {
                Write-Host "Warning: Verification failed for $($app.Name). Restart may be required." -ForegroundColor Yellow
            }
        } else {
            $ErrorOccurred = $true
            Write-Host "Installation failed for $($app.Name). Exit Code: $exitCode" -ForegroundColor Red
        }
    }
} catch {
    $ErrorOccurred = $true
    Write-Error "Unexpected error: $($_.Exception.Message)"
} finally {
    Stop-Transcript
    Write-Host "`nInstallation attempt finished. Log saved to: $logFilePath" -ForegroundColor Cyan
    if ($ErrorOccurred) {
        Write-Warning "One or more errors occurred. Review the log file for details."
    }
    Read-Host "Press Enter to exit"
}
