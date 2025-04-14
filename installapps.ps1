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

function Install-Scoop {
    try {
        Write-Log "Attempting Scoop installation"
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
        Write-Log "Scoop installed successfully"
    } catch {
        $errorMsg = "ERROR: Failed to install Scoop: $_"
        Write-Host $errorMsg -ForegroundColor Red
        Write-Log $errorMsg
        exit 1
    }
}

# Check and install package managers
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "Scoop not found, installing..." -ForegroundColor Yellow
    Write-Log "Scoop not found, installing..."
    Install-Scoop
    
    # Add essential buckets
    Write-Log "Adding essential Scoop buckets"
    scoop bucket add extras
    scoop bucket add versions
    scoop bucket add nerd-fonts
    scoop bucket add nonportable
    scoop bucket add games
}

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Chocolatey not found, installing..." -ForegroundColor Yellow
    Write-Log "Chocolatey not found, installing..."
    Install-Chocolatey
}

# Software List (Mix of Scoop and Chocolatey)
$softwareList = @(
    @{ Number = 1; Name = "Zen Browser"; Description = "Firefox-based web browser"; Manager = "chocolatey"; Package = "zen-browser" },
    @{ Number = 2; Name = "Greenshot"; Description = "Screenshot tool"; Manager = "scoop"; Package = "greenshot"; Bucket = "extras" },
    @{ Number = 3; Name = "Revo Uninstaller"; Description = "Advanced uninstaller"; Manager = "scoop"; Package = "revouninstaller"; Bucket = "extras" },
    @{ Number = 4; Name = ".NET 6 Runtime"; Description = "Microsoft .NET runtime"; Manager = "chocolatey"; Package = "dotnet-6.0-runtime" },
    @{ Number = 5; Name = "VC++ AIO"; Description = "Visual C++ Redistributables"; Manager = "scoop"; Package = "vcredist-aio"; Bucket = "extras" },
    @{ Number = 6; Name = "WebView2 Runtime"; Description = "Edge WebView2 runtime"; Manager = "chocolatey"; Package = "webview2-runtime" },
    @{ Number = 7; Name = "Everything Search"; Description = "Fast file search tool"; Manager = "scoop"; Package = "everything"; Bucket = "extras" },
    @{ Number = 8; Name = "Everything Toolbar"; Description = "Search toolbar for Windows"; Manager = "scoop"; Package = "everythingtoolbar"; Bucket = "extras" },
    @{ Number = 9; Name = "Free Download Manager"; Description = "Download accelerator"; Manager = "scoop"; Package = "freedownloadmanager"; Bucket = "extras" },
    @{ Number = 10; Name = "Icaros Shell"; Description = "Media file thumbnails"; Manager = "scoop"; Package = "icaros-np"; Bucket = "nonportable" },
    @{ Number = 11; Name = "NanaZip"; Description = "File archiver"; Manager = "scoop"; Package = "nanazip"; Bucket = "main" },
    @{ Number = 12; Name = "Spotify"; Description = "Music streaming service"; Manager = "scoop"; Package = "spotify"; Bucket = "extras" },
    @{ Number = 13; Name = "YouTube Music"; Description = "Music player"; Manager = "scoop"; Package = "youtube-music"; Bucket = "extras" },
    @{ Number = 14; Name = "Vesktop"; Description = "Enhanced Discord client"; Manager = "scoop"; Package = "vesktop"; Bucket = "extras" },
    @{ Number = 15; Name = "Flow Launcher"; Description = "Productivity launcher"; Manager = "scoop"; Package = "flow-launcher"; Bucket = "extras" },
    @{ Number = 16; Name = "NextDNS"; Description = "DNS privacy tool"; Manager = "scoop"; Package = "nextdns"; Bucket = "main" },
    @{ Number = 17; Name = "Notepad++"; Description = "Text/code editor"; Manager = "scoop"; Package = "notepadplusplus"; Bucket = "extras" },
    @{ Number = 18; Name = "Oracle VirtualBox"; Description = "Virtualization tool"; Manager = "scoop"; Package = "virtualbox-np"; Bucket = "nonportable" },
    @{ Number = 19; Name = "EarTrumpet"; Description = "Volume control utility"; Manager = "scoop"; Package = "eartrumpet"; Bucket = "extras" },
    @{ Number = 20; Name = "Spicetify + Themes"; Description = "Spotify customization tool"; Manager = "scoop"; Package = "spicetify-cli spicetify-themes"; Bucket = "extras" },
    @{ Number = 21; Name = "AutoHotkey"; Description = "Automation scripting"; Manager = "scoop"; Package = "autohotkey"; Bucket = "extras" },
    @{ Number = 22; Name = "Playnite"; Description = "Game library manager"; Manager = "scoop"; Package = "playnite"; Bucket = "extras" },
    @{ Number = 23; Name = "PowerToys"; Description = "Windows utilities"; Manager = "scoop"; Package = "powertoys"; Bucket = "extras" },
    @{ Number = 24; Name = "Rainmeter"; Description = "Desktop customization"; Manager = "scoop"; Package = "rainmeter"; Bucket = "extras" },
    @{ Number = 25; Name = "UnigetUI"; Description = "Package manager GUI"; Manager = "scoop"; Package = "unigetui"; Bucket = "extras" },
    @{ Number = 26; Name = "Windows Terminal"; Description = "Modern terminal"; Manager = "scoop"; Package = "windows-terminal"; Bucket = "extras" },
    @{ Number = 27; Name = "Alacritty"; Description = "GPU-accelerated terminal"; Manager = "scoop"; Package = "alacritty"; Bucket = "extras" },
    @{ Number = 28; Name = "Zoom"; Description = "Video conferencing tool"; Manager = "scoop"; Package = "zoom"; Bucket = "extras" },
    @{ Number = 29; Name = "Windows Subsystem for Linux 2"; Description = "Linux environment on Windows"; Manager = "chocolatey"; Package = "wsl2" },
    @{ Number = 30; Name = "Cygwin"; Description = "Linux-like environment for Windows"; Manager = "chocolatey"; Package = "cygwin" },
    @{ Number = 31; Name = "Cyg-get"; Description = "Utility to install Cygwin packages"; Manager = "chocolatey"; Package = "cyg-get" },
    @{ Number = 32; Name = "Cursor"; Description = "AI-powered code editor"; Manager = "scoop"; Package = "cursor"; Bucket = "extras" },
    @{ Number = 33; Name = "OBS Studio"; Description = "Video recording/streaming"; Manager = "scoop"; Package = "obs-studio"; Bucket = "extras" },
    @{ Number = 34; Name = "Peace APO Equalizer"; Description = "Audio equalizer suite"; Manager = "scoop"; Package = "equalizer-apo-np peace-np"; Bucket = "nonportable"; Sequential = $true },
    @{ Number = 35; Name = "Steam"; Description = "Gaming platform and store"; Manager = "chocolatey"; Package = "steam" }
)

# Display Menu
Write-Host "Select software to install (comma-separated numbers):`n"
$softwareList | ForEach-Object {
    Write-Host "$($_.Number): $($_.Name) - $($_.Description)"
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

        if ($item.Manager -eq "scoop") {
            # Add bucket if specified and not already added
            if ($item.Bucket) {
                $existingBuckets = scoop bucket list
                if (-not ($existingBuckets -match $item.Bucket)) {
                    Write-Log "Adding Scoop bucket: $($item.Bucket)"
                    scoop bucket add $item.Bucket
                }
            }

            Write-Log "Using Scoop for $($item.Name) installation"
            # Handle multiple packages (like spicetify + themes)
            $packages = $item.Package -split ' '
            
            # Check if packages need to be installed sequentially
            if ($item.Sequential) {
                foreach ($package in $packages) {
                    Write-Log "Installing $package"
                    scoop install $package

                    if ($LASTEXITCODE -ne 0) {
                        throw "Scoop installation failed with exit code $LASTEXITCODE for $package"
                    }
                    
                    # For Peace APO, wait a bit after installing equalizer-apo before installing peace
                    if ($package -eq "equalizer-apo-np") {
                        Write-Log "Waiting 5 seconds after equalizer-apo-np installation before installing peace-np"
                        Start-Sleep -Seconds 5
                    }
                }
            } else {
                foreach ($package in $packages) {
                    Write-Log "Installing $package"
                    scoop install $package

                    if ($LASTEXITCODE -ne 0) {
                        throw "Scoop installation failed with exit code $LASTEXITCODE for $package"
                    }
                }
            }
        } else {
            # Custom flags for specific Chocolatey packages
            $chocoArgs = ""
            if ($item.Package -eq "zen-browser") { 
                $chocoArgs += "--pre" 
            }
            if ($item.Package -eq "freedownloadmanager") { 
                $chocoArgs += "--ignore-checksums"
            }

            Write-Log "Using Chocolatey for $($item.Name) installation"
            choco install $item.Package -y --no-progress $(if($chocoArgs){$chocoArgs})

            if ($LASTEXITCODE -ne 0) {
                throw "Chocolatey installation failed with exit code $LASTEXITCODE"
            }
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
