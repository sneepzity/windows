# Font Installer Script with DisplayLink Driver Installation
# Created: 2025-04-10
$ErrorActionPreference = "Stop"
$host.UI.RawUI.WindowTitle = "Font Installer - Keep this window open"

# Configuration
$fontGroups = @{
    "1" = @{
        Name = "Ubuntu Family"
        Fonts = @(
            @{ Name = "Ubuntu"; URL = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Ubuntu.zip" },
            @{ Name = "UbuntuMono"; URL = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/UbuntuMono.zip" },
            @{ Name = "UbuntuSans"; URL = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/UbuntuSans.zip" }
        )
    }
    "2" = @{
        Name = "Monospaced Fonts"
        Fonts = @(
            @{ Name = "Hack"; URL = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Hack.zip" },
            @{ Name = "SourceCodePro"; URL = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/SourceCodePro.zip" },
            @{ Name = "AnonymousPro"; URL = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/AnonymousPro.zip" },
            @{ Name = "JetBrainsMono"; URL = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/JetBrainsMono.zip" },
            @{ Name = "RobotoMono"; URL = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/RobotoMono.zip" },
            @{ Name = "SpaceMono"; URL = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/SpaceMono.zip" },
            @{ Name = "Terminus"; URL = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Terminus.zip" }
        )
    }
    "3" = @{
        Name = "Other Fonts"
        Fonts = @(
            @{ Name = "Noto"; URL = "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.3.0/Noto.zip" }
        )
    }
    "4" = @{
        Name = "SF Pro"
        Fonts = @(
            @{ Name = "SF Pro"; Folder = "SF Pro"; URL = "https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts/raw/refs/heads/master/SF-Pro.ttf" },
            @{ Name = "SF Pro Text"; Folder = "SF Pro"; URL = "https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts/raw/refs/heads/master/SF-Pro-Text-Regular.otf" },
            @{ Name = "SF Pro Rounded"; Folder = "SF Pro"; URL = "https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts/raw/refs/heads/master/SF-Pro-Rounded-Regular.otf" },
            @{ Name = "SF Pro Display"; Folder = "SF Pro"; URL = "https://github.com/sahibjotsaggu/San-Francisco-Pro-Fonts/raw/refs/heads/master/SF-Pro-Display-Regular.otf" }
        )
    }
}
$fontBaseDir = [System.IO.Path]::Combine([Environment]::GetFolderPath("MyDocuments"), "Fonts")
$displayLinkUrl = "https://www.synaptics.com/sites/default/files/exe_files/2025-03/DisplayLink%20USB%20Graphics%20Software%20for%20Windows11.6%20M1-EXE.exe"
$displayLinkInstaller = "$env:TEMP\DisplayLinkInstaller.exe"
$installDisplayLink = $false

# Font existence check [[7]][[9]]
function Is-FontInstalled {
    param ([string]$FontName)
    $regKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"
    if (Test-Path $regKey) {
        return ((Get-Item $regKey).GetValueNames() -contains $FontName)
    }
    return $false
}

# Admin elevation check [[6]][[7]]
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Requesting admin rights..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList @(
        "-NoExit",
        "-NoProfile",
        "-ExecutionPolicy", "Bypass",
        "-File", "`"$PSCommandPath`""
    ) -Verb RunAs
    exit
}

# Create base directory [[1]]
if (-not (Test-Path $fontBaseDir)) {
    try {
        New-Item -ItemType Directory -Path $fontBaseDir -Force | Out-Null
        Write-Host "Created directory: $fontBaseDir" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to create directory: $fontBaseDir" -ForegroundColor Red
        Write-Host "Press any key to exit..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
}

# Font installation function [[1]][[3]]
function Install-Font {
    param ([string]$FontPath)
    try {
        $shell = New-Object -ComObject Shell.Application
        $fontsFolder = $shell.Namespace(0x14)
        $fontsFolder.CopyHere($FontPath, 0x10)
        return $true
    }
    catch {
        Write-Warning "Failed to install $FontPath"
        return $false
    }
}

# Menu functions
function Show-MainMenu {
    Clear-Host
    Write-Host "Select options (enter 'exit' to quit):" -ForegroundColor Cyan
    foreach ($group in $fontGroups.GetEnumerator() | Sort-Object Key) {
        Write-Host "[$($group.Key)] $($group.Value.Name)" -ForegroundColor Yellow
    }
    Write-Host "[5] Install DisplayLink Driver" -ForegroundColor Yellow
}

function Show-FontMenu {
    param ($Group)
    Write-Host "`nFonts in $($Group.Name) (enter 'b' to go back):" -ForegroundColor Cyan
    for ($i = 0; $i -lt $Group.Fonts.Count; $i++) {
        Write-Host "  $($i+1). $($Group.Fonts[$i].Name)"
    }
    Write-Host "  all. Install all fonts in this group"
}

# Main execution
:mainLoop while ($true) {
    Show-MainMenu
    $input = Read-Host "Enter selection (e.g. 1,2,3,4,5) or 'exit'"
    if ($input -eq 'exit') { break mainLoop }
    
    foreach ($selection in ($input -split ',' | ForEach-Object { $_.Trim() })) {
        if ($selection -eq '5') {
            $installDisplayLink = $true
            break mainLoop
        }
        if (-not $fontGroups.ContainsKey($selection)) {
            Write-Warning "Invalid selection: $selection"
            continue
        }
        
        $group = $fontGroups[$selection]
        :fontLoop while ($true) {
            Show-FontMenu -Group $group
            $fontChoice = Read-Host "Enter font numbers (e.g. 1,3), 'all', or 'b'"
            if ($fontChoice -eq 'b') { break fontLoop }
            
            $selectedFonts = if ($fontChoice -eq 'all') {
                $group.Fonts
            } else {
                $selectedIndices = $fontChoice -split ',' | ForEach-Object { $_.Trim() }
                $selectedIndices | ForEach-Object {
                    if ($_ -match '^\d+$' -and [int]$_ -ge 1 -and [int]$_ -le $group.Fonts.Count) {
                        $group.Fonts[[int]$_ - 1]
                    } else {
                        Write-Warning "Invalid font number: $_"
                    }
                }
            }
            
            foreach ($font in $selectedFonts) {
                try {
                    $fontSubDir = Join-Path $fontBaseDir $(if ($font.Folder) { $font.Folder } else { $font.Name })
                    if (-not (Test-Path $fontSubDir)) {
                        New-Item -ItemType Directory -Path $fontSubDir -Force | Out-Null
                    }
                    
                    if ($font.URL.EndsWith(".zip", "OrdinalIgnoreCase")) {
                        $zipPath = "$env:TEMP\$($font.Name).zip"
                        Invoke-WebRequest -Uri $font.URL -OutFile $zipPath
                        Expand-Archive -Path $zipPath -DestinationPath $fontSubDir -Force
                        Remove-Item $zipPath -ErrorAction SilentlyContinue
                    } else {
                        $fileName = [System.IO.Path]::GetFileName($font.URL)
                        $fontPath = Join-Path $fontSubDir $fileName
                        Invoke-WebRequest -Uri $font.URL -OutFile $fontPath
                    }
                    
                    $fontFiles = Get-ChildItem -Path $fontSubDir -Include *.ttf, *.otf -Recurse
                    foreach ($file in $fontFiles) {
                        $fontName = [System.IO.Path]::GetFileNameWithoutExtension($file)
                        if (Is-FontInstalled $fontName) {
                            Write-Host "`n  Font '$fontName' already installed. Skipping..." -ForegroundColor Yellow
                            continue
                        }
                        Install-Font -FontPath $file.FullName
                    }
                    Write-Host "  Installation complete" -ForegroundColor Green
                }
                catch {
                    Write-Host " Failed" -ForegroundColor Red
                    Write-Warning "Error processing $($font.Name): $_"
                    Write-Host "Press any key to continue..." -ForegroundColor Yellow
                    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                }
            }
        }
    }
}

# DisplayLink Installation
if ($installDisplayLink) {
    $confirm = Read-Host "`nInstall DisplayLink USB Graphics driver? (Y/N)"
    if ($confirm -match '^[Yy]') {
        try {
            Invoke-WebRequest -Uri $displayLinkUrl -OutFile $displayLinkInstaller
            $process = Start-Process -FilePath $displayLinkInstaller -ArgumentList "/quiet /norestart" -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-Host "DisplayLink installation succeeded" -ForegroundColor Green
            } else {
                Write-Host "DisplayLink installation failed with code $($process.ExitCode)" -ForegroundColor Red
            }
        }
        catch {
            Write-Host "DisplayLink installation failed: $_" -ForegroundColor Red
        }
        finally {
            Remove-Item $displayLinkInstaller -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "`nOperation complete" -ForegroundColor Cyan
Write-Host "Press Enter to exit..." -ForegroundColor Yellow
Read-Host | Out-Null
