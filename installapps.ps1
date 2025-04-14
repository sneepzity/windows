# Ensure TLS 1.2 [[7]]
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Setup Logging
$logFile = "$env:USERPROFILE\Documents\SoftwareInstall.log"
function Write-Log {
    param([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "$timestamp - $message"
}

Write-Log "Starting installation script"

# Check and elevate privileges [[5]][[6]]
$currentPrincipal = [Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Log "Not running as administrator, attempting elevation..."
    $scriptPath = $PSCommandPath
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" $args"
    
    try {
        Start-Process -FilePath "powershell" -ArgumentList $arguments -Verb RunAs -ErrorAction Stop
        Write-Log "Elevation successful"
        exit
    } catch {
        $errorMsg = "Elevation failed: $_"
        Write-Host $errorMsg -ForegroundColor Red
        Write-Log $errorMsg
        exit 1
    }
}

# Package Manager Setup
function Install-Chocolatey {
    try {
        Write-Log "Attempting Chocolatey installation"
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1')) | Out-Null
        Write-Log "Chocolatey installed successfully"
    } catch {
        $errorMsg = "ERROR: Failed to install Chocolatey: $_"
        Write-Host $errorMsg -ForegroundColor Red
        Write-Log $errorMsg
        exit 1
    }
}

function Install-Winget {
    try {
        Write-Log "Attempting Winget installation"
        $progressPreference = 'silentlyContinue'
        $wingetMsix = "$env:TEMP\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        Invoke-WebRequest -Uri "https://aka.ms/getwinget" -OutFile $wingetMsix
        Add-AppxPackage -Path $wingetMsix
        Remove-Item $wingetMsix
        Write-Log "Winget installed successfully"
    } catch {
        $errorMsg = "ERROR: Failed to install Winget: $_"
        Write-Host $errorMsg -ForegroundColor Red
        Write-Log $errorMsg
        exit 1
    }
}

# Check and install package managers
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Log "Chocolatey not found, installing..."
    Install-Chocolatey
}

if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Log "Winget not found, installing..."
    Install-Winget
}

# Software List (Enforced managers)
$softwareList = @(
    @{ Number = 1; Name = "Zen Browser"; Description = "Firefox-based web browser"; Package = "zen-browser" },
    @{ Number = 2; Name = "Greenshot"; Description = "Screenshot tool"; Package = "greenshot" },
    @{ Number = 3; Name = "Revo Uninstaller"; Description = "Advanced uninstaller"; Package = "revo-uninstaller" },
    @{ Number = 4; Name = ".NET 6 Runtime"; Description = "Microsoft .NET runtime"; Package = "dotnet-6.0-runtime" },
    @{ Number = 5; Name = "VC++ AIO"; Description = "Visual C++ Redistributables"; Package = "vcredist-all" },
    @{ Number = 6; Name = "WebView2 Runtime"; Description = "Edge WebView2 runtime"; Package = "webview2-runtime" },
    @{ Number = 7; Name = "Everything Search"; Description = "Fast file search tool"; Package = "everything" },
    @{ Number = 8; Name = "Everything Toolbar"; Description = "Search toolbar for Windows"; Package = "everythingtoolbar" },
    @{ Number = 9; Name = "Free Download Manager"; Description = "Download accelerator"; Package = "freedownloadmanager" },
    @{ Number = 10; Name = "Icaros Shell"; Description = "Media file thumbnails"; Package = "icaros" },
    @{ Number = 11; Name = "NanaZip"; Description = "File archiver"; Package = "nanazip" },
    @{ Number = 12; Name = "Spotify"; Description = "Music streaming service"; Package = "spotify" },
    @{ Number = 13; Name = "YouTube Music"; Description = "Music player"; Package = "th-ch-youtube-music" },
    @{ Number = 14; Name = "Vesktop"; Description = "Desktop environment"; Package = "Vesktop" },
    @{ Number = 15; Name = "Flow Launcher"; Description = "Productivity launcher"; Package = "flow-launcher" },
    @{ Number = 16; Name = "NextDNS"; Description = "DNS privacy tool"; Package = "nextdns" },
    @{ Number = 17; Name = "Notepad++"; Description = "Text/code editor"; Package = "notepadplusplus" },
    @{ Number = 18; Name = "Oracle VirtualBox"; Description = "Virtualization tool"; Package = "virtualbox" },
    @{ Number = 19; Name = "EarTrumpet"; Description = "Volume control utility"; Package = "eartrumpet" },
    @{ Number = 20; Name = "Spicetify"; Description = "Spotify customization tool"; Package = "spicetify-cli" },
    @{ Number = 21; Name = "AutoHotkey"; Description = "Automation scripting"; Package = "autohotkey" },
    @{ Number = 22; Name = "Playnite"; Description = "Game library manager"; Package = "playnite" },
    @{ Number = 23; Name = "PowerToys"; Description = "Windows utilities"; Package = "powertoys" },
    @{ Number = 24; Name = "Rainmeter"; Description = "Desktop customization"; Package = "rainmeter" },
    @{ Number = 25; Name = "UnigetUI"; Description = "Package manager GUI"; Package = "unigetui" },
    @{ Number = 26; Name = "Windows Terminal"; Description = "Modern terminal"; Package = "microsoft-windows-terminal" },
    @{ Number = 27; Name = "Alacritty"; Description = "GPU-accelerated terminal"; Package = "alacritty" },
    @{ Number = 28; Name = "Zoom"; Description = "Video conferencing tool"; Package = "zoom" },
    @{ Number = 29; Name = "Windows Subsystem for Linux 2"; Description = "Linux environment on Windows"; Package = "wsl2" },
    @{ Number = 30; Name = "Cygwin"; Description = "Linux-like environment for Windows"; Package = "cygwin" },
    @{ Number = 31; Name = "Cyg-get"; Description = "Utility to install Cygwin packages and their dependencies"; Package = "cyg-get" }
)

# Display Menu
Write-Host "Select software to install (comma-separated numbers):`n"
$softwareList | ForEach-Object {
    $manager = if ($_.Package -eq "Vesktop") { "winget" } else { "choco" }
    Write-Host "$($_.Number): $($_.Name) - $($_.Description) [$manager]"
}

# Process Selection
$selection = Read-Host "`nEnter numbers (e.g., 1,3,5)"
$selectedNumbers = $selection -split ',' | ForEach-Object { $_.Trim() }

foreach ($num in $selectedNumbers) {
    try {
        $item = $softwareList | Where-Object { $_.Number -eq [int]$num }
        
        if (-not $item) {
            throw "Invalid selection: $num"
        }
        
        Write-Log "Selected: $($item.Name) ($($item.Package))"
        Write-Host "Installing $($item.Name)..."

        # Enforce package managers [[3]][[4]][[10]]
        if ($item.Package -eq "Vesktop") {
            Write-Log "Using Winget for Vesktop installation"
            winget install --id $item.Package --exact --silent --accept-package-agreements
        } else {
            Write-Log "Using Chocolatey for $($item.Name) installation"
            choco install $item.Package -y --no-progress
        }

        if ($LASTEXITCODE -ne 0) {
            throw "Installation failed with exit code $LASTEXITCODE"
        }

        Write-Log "Successfully installed $($item.Name)"
        
    } catch {
        $errorMsg = "ERROR installing $($item.Name): $_"
        Write-Host $errorMsg -ForegroundColor Red
        Write-Log $errorMsg
    }
}

Write-Host "`nInstallation complete! Log file: $logFile"
Write-Log "Installation process completed"
