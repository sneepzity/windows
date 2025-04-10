# Font Installer Script with DisplayLink Driver Installation
# Created: 2025-04-10

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
}

$fontBaseDir = [System.IO.Path]::Combine([Environment]::GetFolderPath("MyDocuments"), "Fonts")
$displayLinkUrl = "https://www.synaptics.com/sites/default/files/exe_files/2025-03/DisplayLink%20USB%20Graphics%20Software%20for%20Windows11.6%20M1-EXE.exe"
$displayLinkInstaller = "$env:TEMP\DisplayLinkInstaller.exe"
$installDisplayLink = $false

# Admin elevation check [[3]][[7]]
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Requesting admin rights for font installation..." -ForegroundColor Yellow
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Create base font directory if needed
if (-not (Test-Path $fontBaseDir)) {
    try {
        New-Item -ItemType Directory -Path $fontBaseDir -Force | Out-Null
        Write-Host "Created directory: $fontBaseDir" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to create directory: $fontBaseDir" -ForegroundColor Red
        exit 1
    }
}

# Font installation function using COM [[1]][[3]]
function Install-Font {
    param (
        [string]$FontPath
    )
    try {
        $shell = New-Object -ComObject Shell.Application
        $fontsFolder = $shell.Namespace(0x14)  # Fonts folder constant [[1]]
        $fontsFolder.CopyHere($FontPath, 0x10) # 0x10 = Silent flag [[1]]
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
    Write-Host "[4] Install DisplayLink Driver" -ForegroundColor Yellow
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
    $input = Read-Host "Enter selection (e.g. 1,2,3,4) or 'exit'"
    
    if ($input -eq 'exit') {
        Write-Host "Exiting script..." -ForegroundColor Yellow
        break mainLoop
    }
    
    $selections = $input -split ',' | ForEach-Object { $_.Trim() }
    
    foreach ($selection in $selections) {
        if ($selection -eq '4') {
            $installDisplayLink = $true
            break mainLoop  # Immediate exit to process DisplayLink [[2]][[4]]
        }
        
        if (-not $fontGroups.ContainsKey($selection)) {
            Write-Warning "Invalid selection: $selection"
            continue
        }
        
        $group = $fontGroups[$selection]
        
        :fontLoop while ($true) {
            Show-FontMenu -Group $group
            $fontChoice = Read-Host "Enter font numbers (e.g. 1,3), 'all', or 'b'"
            
            if ($fontChoice -eq 'b') {
                break fontLoop
            }
            
            if ($fontChoice -eq 'all') {
                $selectedFonts = $group.Fonts
            } else {
                $selectedIndices = $fontChoice -split ',' | ForEach-Object { $_.Trim() }
                $selectedFonts = @()
                foreach ($index in $selectedIndices) {
                    if ([int]$index -ge 1 -and [int]$index -le $group.Fonts.Count) {
                        $selectedFonts += $group.Fonts[[int]$index - 1]
                    } else {
                        Write-Warning "Invalid font number: $index"
                    }
                }
            }
            
            foreach ($font in $selectedFonts) {
                try {
                    $zipPath = "$env:TEMP\$($font.Name).zip"
                    $fontSubDir = Join-Path -Path $fontBaseDir -ChildPath $font.Name
                    
                    # Create font-specific directory
                    if (-not (Test-Path $fontSubDir)) {
                        New-Item -ItemType Directory -Path $fontSubDir -Force | Out-Null
                    }
                    
                    # Download font
                    Write-Host "  Downloading $($font.Name)..." -NoNewline
                    Invoke-WebRequest -Uri $font.URL -OutFile $zipPath -ErrorAction Stop
                    Write-Host " Done" -ForegroundColor Green
                    
                    # Extract to subdirectory
                    Write-Host "  Extracting to $fontSubDir..." -NoNewline
                    Expand-Archive -Path $zipPath -DestinationPath $fontSubDir -Force -ErrorAction Stop
                    Write-Host " Done" -ForegroundColor Green
                    
                    # Install fonts system-wide [[1]][[3]]
                    Write-Host "  Installing fonts..." -NoNewline
                    $fontFiles = Get-ChildItem -Path $fontSubDir -Include *.ttf, *.otf -Recurse
                    foreach ($file in $fontFiles) {
                        Install-Font -FontPath $file.FullName | Out-Null
                    }
                    Write-Host " Done" -ForegroundColor Green
                    
                    # Cleanup
                    Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
                }
                catch {
                    Write-Host " Failed" -ForegroundColor Red
                    Write-Warning "Error processing $($font.Name): $_"
                }
            }
        }
    }
}

# DisplayLink Installation
if ($installDisplayLink) {
    $confirm = Read-Host "`nInstall DisplayLink USB Graphics driver? (Y/N)"
    if ($confirm -eq 'Y' -or $confirm -eq 'y') {
        Write-Host "Installing DisplayLink Driver..." -ForegroundColor Cyan
        try {
            # Download installer
            Invoke-WebRequest -Uri $displayLinkUrl -OutFile $displayLinkInstaller -ErrorAction Stop
            
            # Silent install
            $process = Start-Process -FilePath $displayLinkInstaller -ArgumentList "/quiet /norestart" -Wait -PassThru
            if ($process.ExitCode -eq 0) {
                Write-Host "DisplayLink installation succeeded" -ForegroundColor Green
            }
            else {
                Write-Host "DisplayLink installation failed with code $($process.ExitCode)" -ForegroundColor Red
            }
            
            # Cleanup
            Remove-Item -Path $displayLinkInstaller -Force -ErrorAction SilentlyContinue
        }
        catch {
            Write-Host "DisplayLink installation failed: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Skipping DisplayLink installation" -ForegroundColor Yellow
    }
}

Write-Host "`nOperation complete" -ForegroundColor Cyan
