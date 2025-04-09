# Set TLS 1.2 for compatibility [[5]]
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Create Wallpapers folder [[6]]
$wallpaperPath = "$env:USERPROFILE\Pictures\Wallpapers"
if (-not (Test-Path $wallpaperPath)) {
    New-Item -Path $wallpaperPath -ItemType Directory | Out-Null
}

# Download wallpapers using Invoke-WebRequest
$wallpapers = @{
    'https://s6.imgcdn.dev/YjXrqt.jpg' = 'madoka-creepy.jpg'
    'https://s6.imgcdn.dev/YjXx4T.jpg' = 'yosemite.jpg'
    'https://s6.imgcdn.dev/YjX20D.png' = 'madoka-circular.png'
    'https://s6.imgcdn.dev/YjXAd9.jpg' = 'madoka-center.jpg'
    'https://s6.imgcdn.dev/YjXZjy.jpg' = 'madoka-standing.jpg'
    'https://s6.imgcdn.dev/YjX9P8.jpg' = 'madoka-promotion.jpg'
    'https://s6.imgcdn.dev/YjXR92.jpg' = 'nature-nordic-original.jpg'
    'https://s6.imgcdn.dev/YjXVJi.jpg' = 'nordic-original.jpg'
}

foreach ($url in $wallpapers.Keys) {
    $file = Join-Path $wallpaperPath $wallpapers[$url]
    Invoke-WebRequest -Uri $url -OutFile $file
}

# Software list with updated URLs
$software = @(
    [PSCustomObject]@{
        Name = '1. Nvidia Driver'
        Url = 'https://us.download.nvidia.com/Windows/572.83/572.83-desktop-win10-win11-64bit-international-dch-whql.exe'
    },
    [PSCustomObject]@{
        Name = '2. AMD Adrenalin'
        Url = 'https://www.dropbox.com/scl/fi/2cl99uln2bd1wjxisq32t/amd-software-adrenalin-edition-25.3.1-minimalsetup-250312_web.exe?rlkey=78wlc3ociptyhou8rogvnxlax&st=tyosznrf&dl=1'
    },
    [PSCustomObject]@{
        Name = '3. Auto Clicker'
        Url = 'https://zenlayer.dl.sourceforge.net/project/orphamielautoclicker/autoclicker-3.0/AutoClicker-3.1.exe'
    },
    [PSCustomObject]@{
        Name = '4. Explorer Patcher'
        Url = 'https://github.com/valinet/ExplorerPatcher/releases/latest/download/ep_setup.exe'
    },
    [PSCustomObject]@{
        Name = '5. FishStrap'
        Url = 'https://github.com/fishstrap/fishstrap/releases/download/v2.9.1.1/Fishstrap-v2.9.1.1.exe'
    },
    [PSCustomObject]@{
        Name = '6. TinyTask'
        Url = 'https://github.com/frankwick/t/raw/main/tinytask.exe'
    },
    [PSCustomObject]@{
        Name = '7. VC++ AIO'
        Url = 'https://sg1-dl.techpowerup.com/files/x3VC5zbRkJtwGtCoXwalAQ/1744229814/Visual-C-Runtimes-All-in-One-Mar-2025.zip'
    },
    [PSCustomObject]@{
        Name = '8. Acer Nitro Drivers'
        Url = 'https://drive.google.com/uc?export=download&id=1BWNQRHOtI22mKSy_z3isS5bu1HMgU_0W'
    }
)

Write-Host "`nAvailable software:"
$software | ForEach-Object { Write-Host $_.Name }

$selection = Read-Host "`nEnter numbers separated by commas (1-8)"
$selected = $selection -split ',' | ForEach-Object { [int]$_ - 1 }

foreach ($index in $selected) {
    if ($index -ge 0 -and $index -lt $software.Count) {
        $item = $software[$index]
        
        # Get filename from URL
        $uri = [System.Uri]$item.Url
        $fileName = [System.IO.Path]::GetFileName($uri.AbsolutePath)
        
        # Special case for Explorer Patcher to keep original name
        if ($item.Name -eq '4. Explorer Patcher') {
            $fileName = [System.IO.Path]::GetFileName($uri.AbsolutePath)
        }
        
        $file = Join-Path $env:USERPROFILE\Downloads $fileName
        
        Write-Host "Downloading $($item.Name)..."
        try {
            Invoke-WebRequest -Uri $item.Url -OutFile $file -ErrorAction Stop
            
            # Add Defender exclusions only for successful Explorer Patcher download
            if ($item.Name -eq '4. Explorer Patcher') {
                Write-Host "Adding Windows Defender exclusions..."
                Add-MpPreference -ExclusionPath "C:\Program Files\ExplorerPatcher"
                Add-MpPreference -ExclusionPath "$env:APPDATA\ExplorerPatcher"
                Add-MpPreference -ExclusionPath "C:\Windows\dxgi.dll"
                Add-MpPreference -ExclusionPath "C:\Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy"
                Add-MpPreference -ExclusionPath "C:\Windows\SystemApps\ShellExperienceHost_cw5n1h2txyewy"
            }

            ### NEW AUTOMATION CODE FOR TINYTASK/AUTOCLICKER ###
            if ($item.Name -match '3\. Auto Clicker|6\. TinyTask') {
                $automationPath = "C:\Program Files\Automation"
                
                # Create directory if needed
                if (-not (Test-Path $automationPath)) {
                    New-Item -Path $automationPath -ItemType Directory -Force | Out-Null
                }

                # Move executable
                $destination = Join-Path $automationPath $fileName
                Move-Item -Path $file -Destination $destination -Force

                # Create Start Menu shortcut
                $startMenuPath = [Environment]::GetFolderPath("Programs")
                $shortcutName = ($item.Name -replace '^\d+\. ').Trim() + ".lnk"
                $shortcutPath = Join-Path $startMenuPath $shortcutName
                $shell = New-Object -ComObject WScript.Shell
                $shortcut = $shell.CreateShortcut($shortcutPath)
                $shortcut.TargetPath = $destination
                $shortcut.Save()
                
                Write-Host "Moved to $automationPath and added to Start Menu" -ForegroundColor Green
            }
            ### END NEW CODE ###

        } catch {
            Write-Host "Failed: $_" -ForegroundColor Red
        }
    }
}
