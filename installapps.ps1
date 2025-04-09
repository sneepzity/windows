# PowerShell Script to Selectively Install Applications using Winget
# Includes Winget check/install attempt and logging to Documents folder.

# --- Configuration ---
# Set to $false if you want to manually review the winget installer script from winget.pro first
$AutoInstallWinget = $true

# --- Winget Check ---
Write-Host "Checking for Winget command..." -ForegroundColor Yellow
$wingetCmd = Get-Command winget -ErrorAction SilentlyContinue

if ($null -eq $wingetCmd) {
    Write-Warning "Winget command not found."
    if ($AutoInstallWinget) {
        Write-Host "Attempting to install Winget using winget.pro..." -ForegroundColor Yellow
        Write-Warning "SECURITY NOTE: Running scripts directly from the internet (like 'irm | iex') carries risks."
        Write-Warning "winget.pro is a community resource, ensure you trust it or review its script manually first."
        Write-Warning "The official way to get Winget is via the 'App Installer' package in the Microsoft Store."

        try {
            # Safer approach - download script first, then execute if desired
            $tempScriptPath = Join-Path $env:TEMP "InstallWinget.ps1"
            Invoke-RestMethod -Uri "https://winget.pro" -OutFile $tempScriptPath
            
            # Display first few lines of script for review (optional)
            Write-Host "First 10 lines of downloaded script (review):" -ForegroundColor Cyan
            Get-Content $tempScriptPath -TotalCount 10 | ForEach-Object { Write-Host "  $_" }
            
            # Prompt for confirmation before executing
            $confirmation = Read-Host "Do you want to proceed with running this script? (Y/N)"
            if ($confirmation -eq 'Y' -or $confirmation -eq 'y') {
                # Execute the script
                & $tempScriptPath
                
                # Wait a moment for changes to potentially register
                Start-Sleep -Seconds 5
                
                # Verify installation
                $wingetCmd = Get-Command winget -ErrorAction SilentlyContinue
                if ($null -eq $wingetCmd) {
                    Write-Error "Winget installation via script failed or requires a shell restart/system update."
                    Write-Error "Please install/update 'App Installer' from the Microsoft Store manually and try running this script again."
                    Read-Host "Press Enter to exit"
                    exit 1 # Exit with an error code
                } else {
                    Write-Host "Winget command is now available." -ForegroundColor Green
                }
            } else {
                Write-Error "Winget installation cancelled by user."
                Write-Error "Please install/update 'App Installer' from the Microsoft Store manually and try running this script again."
                Read-Host "Press Enter to exit"
                exit 1
            }
        } catch {
            Write-Error "An error occurred during the Winget installation script execution: $($_.Exception.Message)"
            Write-Error "Please install/update 'App Installer' from the Microsoft Store manually and try running this script again."
            Read-Host "Press Enter to exit"
            exit 1
        }
    } else {
         Write-Error "Winget not found and automatic installation is disabled."
         Write-Error "Please install/update 'App Installer' from the Microsoft Store manually and try running this script again."
         Read-Host "Press Enter to exit"
         exit 1
    }
} else {
    Write-Host "Winget found." -ForegroundColor Green
}

# --- Define App List ---
Write-Host "Preparing list of available applications..." -ForegroundColor Cyan
# Define list of applications with names, IDs, and descriptions
$apps = @(
    [PSCustomObject]@{Name="Greenshot"; ID="Greenshot.Greenshot"; Description="Screen capture tool with annotation features."}
    [PSCustomObject]@{Name="Revo Uninstaller"; ID="VSRevoGroup.RevoUninstaller"; Description="Uninstaller utility to remove programs and leftover files/registry entries."}
    [PSCustomObject]@{Name="Zen Browser"; ID="Zen-Team.Zen-Browser"; Description="Privacy-focused web browser."}
    [PSCustomObject]@{Name=".NET 6 Desktop Runtime"; ID="Microsoft.DotNet.DesktopRuntime.6"; Description="Microsoft framework required to run applications built for .NET 6."}
    [PSCustomObject]@{Name="Visual C++ Redistributable (2015+)"; ID="Microsoft.VCRedist.2015+.Latest"; Description="Microsoft libraries required by many applications developed with Visual C++."}
    [PSCustomObject]@{Name="MS Edge WebView2 Runtime"; ID="Microsoft.EdgeWebView2Runtime"; Description="Embeds web content in applications using the Edge rendering engine."}
    [PSCustomObject]@{Name="Everything Search"; ID="voidtools.Everything"; Description="Instant file and folder name search tool for Windows."}
    [PSCustomObject]@{Name="EverythingToolbar"; ID="stnkl.EverythingToolbar"; Description="Integrates Everything Search into the Windows Taskbar."}
    [PSCustomObject]@{Name="Free Download Manager"; ID="FreeDownloadManager.FreeDownloadManager"; Description="Download accelerator and manager."}
    [PSCustomObject]@{Name="Icaros Shell Extensions"; ID="Xanashi.Icaros"; Description="Provides Windows Explorer thumbnails for various video file types."}
    [PSCustomObject]@{Name="NanaZip"; ID="M2Team.NanaZip"; Description="Open-source file archiver (alternative to WinRAR/7-Zip)."}
    [PSCustomObject]@{Name="WizTree Disk Space Analyzer"; ID="AntibodySoftware.WizTree"; Description="Fast disk space analyzer to see what uses storage."}
    [PSCustomObject]@{Name="Flow Launcher"; ID="FlowLauncher.FlowLauncher"; Description="Quick application launcher and file search utility."}
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

# --- Display Application Menu with Descriptions ---
Write-Host "--------------------------------------------------" -ForegroundColor Green
Write-Host "Available applications to install via Winget:" -ForegroundColor Green
Write-Host "--------------------------------------------------"
for ($i = 0; $i -lt $apps.Count; $i++) {
    Write-Host ("[{0}] {1}" -f ($i + 1), $apps[$i].Name) -ForegroundColor White
    Write-Host ("    - {0}" -f $apps[$i].Description) -ForegroundColor Gray # Simple dash instead of special characters
}
Write-Host "--------------------------------------------------"

# --- Get User Selection with Improved Validation ---
$userInput = $null
while ($userInput -eq $null) {
    $rawInput = Read-Host "Enter the numbers for the apps you want to install, separated by commas WITHOUT spaces (e.g. 1,5,12)"
    
    # More thorough validation
    $isValid = $true
    $selectedIndices = @()
    
    # Early validation of format
    if ($rawInput -match '^[1-9]\d*(,[1-9]\d*)*$') {
        $inputNumbers = $rawInput -split ','
        
        foreach ($num in $inputNumbers) {
            $index = [int]$num
            # Check if within valid range (1 to apps.Count)
            if ($index -lt 1 -or $index -gt $apps.Count) {
                Write-Warning "Invalid selection: '$num' is not in range (1-$($apps.Count)). Please try again."
                $isValid = $false
                break
            }
            $selectedIndices += $index
        }
        
        if ($isValid) {
            $userInput = $rawInput
        }
    } else {
        Write-Warning "Invalid input format. Please enter only numbers separated by commas (e.g. 1,5,12)."
    }
}

# --- Install Selected Applications ---
Write-Host "Installing selected applications..." -ForegroundColor Cyan
$inputNumbers = $userInput -split ','
foreach ($num in $inputNumbers) {
    $index = [int]$num - 1
    $selectedApp = $apps[$index]
    Write-Host ("Installing {0} ({1})..." -f $selectedApp.Name, $selectedApp.ID) -ForegroundColor Yellow
    winget install --id=$selectedApp.ID --silent --accept-package-agreements --accept-source-agreements
}
Write-Host "Installation process completed." -ForegroundColor Green

# --- Prepare for Installation & Logging ---
$selectedIndices = $userInput -split ',' # Split string into array of number strings
$documentsPath = [Environment]::GetFolderPath('MyDocuments')
# Ensure the directory exists (optional, usually does)
if (-not (Test-Path -Path $documentsPath)) {
    New-Item -ItemType Directory -Path $documentsPath -Force | Out-Null
}
$logFileName = "winget_install_log_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').txt"
$logFilePath = Join-Path -Path $documentsPath -ChildPath $logFileName

Write-Host "`nStarting installation process for selected apps..." -ForegroundColor Green
Write-Host "A detailed log of this session will be saved to: $logFilePath" -ForegroundColor Cyan
Write-Host "(This includes successes, failures, and Winget command output)"

# --- Process Selection and Install (with Logging using Start-Transcript) ---
$ErrorOccurred = $false # Flag to track if any install failed

try {
    # Start logging everything that appears in the console (output and errors) to the file
    # -Force overwrites if file somehow exists from same second
    Start-Transcript -Path $logFilePath -Force

    Write-Host "`n--- Installation Log Start ---" # Marker for log file readability

    foreach ($selectedIndexStr in $selectedIndices) {
        # Convert string to integer number
        $selectedIndex = [int]$selectedIndexStr - 1 # Convert to 0-based index

        # Validation already done above, but keeping this as an additional safety check
        if ($selectedIndex -ge 0 -and $selectedIndex -lt $apps.Count) {
            $appToInstall = $apps[$selectedIndex]
            $name = $appToInstall.Name
            $id = $appToInstall.ID
            $source = $appToInstall.Source # May be null for most apps, which is fine

            Write-Host "--------------------------------------------------"
            Write-Host "Attempting to install: [$($selectedIndex+1)] $name (ID: $id)" # No color change needed, transcript captures it

            # Prepare the winget command
            $wingetParams = @(
                "install"
                "--id", $id
                "--exact"
                "--accept-package-agreements"
                "--accept-source-agreements"
                "--silent"
                "--disable-interactivity"
            )
            
            # Add source parameter if specified
            if (-not [string]::IsNullOrEmpty($source)) {
                $wingetParams += "--source"
                $wingetParams += $source
            }

            # Execute winget command with parameters
            & winget $wingetParams
            $installExitCode = $LASTEXITCODE

            # Check if installation was successful
            if ($installExitCode -eq 0) {
                Write-Host "$name installed successfully."
                
                # Verify installation by checking if the app is now in the list of installed apps
                $verifyResult = & winget list --id $id --exact
if ($verifyResult -match [regex]::Escape($id)) {
    Write-Host "Verified: $name is now installed." -ForegroundColor Green
} else {
    Write-Host "Warning: Verification failed..." -ForegroundColor Yellow
}
            } else {
                $ErrorOccurred = $true # Mark that at least one error happened
                # Provide feedback based on common winget error codes
                switch ($installExitCode) {
                    -1978335231 { Write-Host "Installation failed for $name. Reason: Package not found (ID '$id' might be incorrect or require a different source). (Exit Code: $installExitCode)" }
                    -1978335243 { Write-Host "Installation failed for $name. Reason: The installer process failed unexpectedly. (Exit Code: $installExitCode)" }
                    -1978335232 { Write-Host "Installation failed for $name. Reason: Download error occurred. Check network connection. (Exit Code: $installExitCode)" }
                    -1978335242 { Write-Host "Installation failed for $name. Reason: Package is already installed. (Exit Code: $installExitCode)" }
                    # Add more known codes here if desired
                    default { Write-Host "Installation command finished with issues for $name (Exit Code: $installExitCode)." }
                }
                Write-Host "Details should be available in the log file. You might need to install it manually, check the ID '$id', or run 'winget source update'."
            }
        } else {
            # This should never happen due to our improved validation, but keeping as a failsafe
            $ErrorOccurred = $true
            Write-Warning "Invalid selection: '$($selectedIndexStr)' is not a valid number in the list (1 - $($apps.Count)). Skipping."
        }
    } # End foreach loop

    Write-Host "`n--- Installation Log End ---" # Marker for log file

} catch {
    $ErrorOccurred = $true
    Write-Error "An unexpected error occurred: $($_.Exception.Message)"
    Write-Error "Stack Trace: $($_.ScriptStackTrace)"
} finally {
    # This block *always* runs, ensuring the transcript is stopped even if errors occur
    Stop-Transcript
    # Output to console *after* stopping transcript
    Write-Host "`nInstallation attempt finished." -ForegroundColor Green
    Write-Host "Log file saved to: $logFilePath" -ForegroundColor Cyan
    if ($ErrorOccurred) {
        Write-Warning "One or more errors occurred during the process. Please review the log file for details."
    }
}

# --- Final Script Message ---
Write-Host "--------------------------------------------------"
Write-Host "Script execution completed." -ForegroundColor Green
Write-Host "To install additional applications, run this script again."
Read-Host "Press Enter to exit"
# End of Script
