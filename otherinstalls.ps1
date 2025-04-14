# Set TLS 1.2 for compatibility
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Create Wallpapers folder
$wallpaperPath = "$env:USERPROFILE\Pictures\Wallpapers"
if (-not (Test-Path $wallpaperPath)) {
    New-Item -Path $wallpaperPath -ItemType Directory | Out-Null
}

# Download wallpapers
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

# Software list with VC++ AIO, AltDrag, and Cursor removed
$software = @(
    [PSCustomObject]@{ Name = '1. Nvidia Driver'; Url = 'https://us.download.nvidia.com/Windows/572.83/572.83-desktop-win10-win11-64bit-international-dch-whql.exe' },
    [PSCustomObject]@{ Name = '2. AMD Adrenalin'; Url = 'https://www.dropbox.com/scl/fi/2cl99uln2bd1wjxisq32t/amd-software-adrenalin-edition-25.3.1-minimalsetup-250312_web.exe?rlkey=78wlc3ociptyhou8rogvnxlax&st=tyosznrf&dl=1' },
    [PSCustomObject]@{ Name = '3. Auto Clicker'; Url = 'https://www.dropbox.com/scl/fi/pel2m2ye2g1ek1j7uet0y/AutoClicker-3.1.exe?rlkey=jjoak7251ls18iwbkdel6l17h&st=mjihmheu&dl=1' },
    [PSCustomObject]@{ Name = '4. Explorer Patcher'; Url = 'https://github.com/valinet/ExplorerPatcher/releases/latest/download/ep_setup.exe' },
    [PSCustomObject]@{ Name = '5. FishStrap'; Url = 'https://github.com/fishstrap/fishstrap/releases/download/v2.9.1.1/Fishstrap-v2.9.1.1.exe' },
    [PSCustomObject]@{ Name = '6. TinyTask'; Url = 'https://github.com/frankwick/t/raw/main/tinytask.exe' },
    [PSCustomObject]@{ Name = '7. Acer Nitro Drivers'; Url = 'https://www.dropbox.com/scl/fi/v0v5u245sj7wjhxsta6hh/Acer-Drivers.zip?rlkey=b6rpezg96beecx42dtcmm542a&st=22eh99xl&dl=1' },
    [PSCustomObject]@{ Name = '8. NVIDIA Broadcast'; Url = 'https://international.download.nvidia.com/Windows/broadcast/2.0.1/NVIDIA_Broadcast_v2.0.1.25267890.exe' }
)

# URL for .NET 6.0 Desktop Runtime
$dotnet6Url = 'https://download.visualstudio.microsoft.com/download/pr/83d32568-c5a2-4117-9700-eb601155ca44/97c71a005e5bf6dc5d1dd513acaadc8f/windowsdesktop-runtime-6.0.28-win-x64.exe'
$dotnet6Path = "$env:TEMP\windowsdesktop-runtime-6.0.28-win-x64.exe"

# Download and handle performance.reg files
Write-Host "Downloading and applying performance tweaks..." -ForegroundColor Cyan
$performanceRegUrl = 'https://www.dropbox.com/scl/fi/k56j578r87egwpk4oh4hp/performance.reg?rlkey=9ag20yi2uo6e5o2bqx4if0ko8&st=17yoy9eo&dl=1'
$removePerformanceRegUrl = 'https://www.dropbox.com/scl/fi/ngdqk4auqll70q8pm7lqz/remove-performance.reg.reg?rlkey=xemmax7cosshlsc3l74yfs2gl&st=jzpc77cj&dl=1'

# Paths for .reg files
$performanceRegPath = "$env:TEMP\performance.reg"
$removePerformanceRegPath = "$env:USERPROFILE\Downloads\remove-performance.reg.reg"

try {
    # Download performance.reg
    Write-Host "Downloading performance.reg from Dropbox..." [[1]]
    Invoke-WebRequest -Uri $performanceRegUrl -OutFile $performanceRegPath -ErrorAction Stop

    # Execute performance.reg
    Write-Host "Applying performance.reg..."
    Start-Process regedit.exe -ArgumentList "/s `"$performanceRegPath`"" -Wait
    Remove-Item $performanceRegPath -Force -ErrorAction SilentlyContinue
    Write-Host "Applied performance.reg successfully" -ForegroundColor Green

    # Download remove-performance.reg.reg
    Write-Host "Downloading remove-performance.reg.reg to Downloads folder..." [[1]]
    Invoke-WebRequest -Uri $removePerformanceRegUrl -OutFile $removePerformanceRegPath -ErrorAction Stop
    Write-Host "Saved remove-performance.reg.reg to Downloads folder" -ForegroundColor Green

} catch {
    Write-Host "Failed to download or apply .reg files: $_" -ForegroundColor Red
}

Write-Host "`nAvailable software:"
$software | ForEach-Object { Write-Host $_.Name }

$selection = Read-Host "`nEnter numbers separated by commas (1-8)"
$selected = $selection -split ',' | ForEach-Object { [int]$_ - 1 }

foreach ($index in $selected) {
    if ($index -ge 0 -and $index -lt $software.Count) {
        $item = $software[$index]
        $uri = [System.Uri]$item.Url
        $fileName = [System.IO.Path]::GetFileName($uri.AbsolutePath)
        $file = Join-Path $env:USERPROFILE\Downloads $fileName
        
        try {
            Write-Host "Downloading $($item.Name)..."
            Invoke-WebRequest -Uri $item.Url -OutFile $file -ErrorAction Stop

            # Automatic installations
            if ($item.Name -match '1\. Nvidia Driver|2\. AMD Adrenalin|4\. Explorer Patcher|5\. FishStrap|8\. NVIDIA Broadcast') {
                Write-Host "Installing $($item.Name)..." -ForegroundColor Cyan

                switch -Wildcard ($item.Name) {
                    '1. Nvidia Driver' {
                        # Non-silent with no restart
                        Start-Process -FilePath $file -ArgumentList "--accept-license --no-restart" -Wait
                        break
                    }
                    '2. AMD Adrenalin' {
                        # Standard installation
                        Start-Process -FilePath $file -Wait
                        break
                    }
                    '4. Explorer Patcher' {
                        # Add Windows Defender exclusions before installation
                        Write-Host "Adding Windows Defender exclusions for Explorer Patcher..." -ForegroundColor Cyan
                        Add-MpPreference -ExclusionPath "C:\Program Files\ExplorerPatcher"
                        Add-MpPreference -ExclusionPath "$env:APPDATA\ExplorerPatcher"
                        Add-MpPreference -ExclusionPath "C:\Windows\dxgi.dll"
                        Add-MpPreference -ExclusionPath "C:\Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy"
                        Add-MpPreference -ExclusionPath "C:\Windows\SystemApps\ShellExperienceHost_cw5n1h2txyewy"
                        
                        # Install Explorer Patcher with default options
                        Start-Process -FilePath $file -Wait
                        break
                    }
                    '5. FishStrap' {
                        # First install .NET 6.0 Desktop Runtime
                        Write-Host "Installing .NET 6.0 Desktop Runtime (required for FishStrap)..." -ForegroundColor Cyan
                        Invoke-WebRequest -Uri $dotnet6Url -OutFile $dotnet6Path -ErrorAction Stop
                        Start-Process -FilePath $dotnet6Path -ArgumentList "/quiet /norestart" -Wait
                        Remove-Item -Path $dotnet6Path -Force -ErrorAction SilentlyContinue
                        Write-Host ".NET 6.0 Desktop Runtime installed successfully" -ForegroundColor Green
                        
                        # Then install FishStrap
                        Start-Process -FilePath $file -Wait
                        break
                    }
                    '8. NVIDIA Broadcast' {
                        # Standard installation
                        Start-Process -FilePath $file -Wait
                        break
                    }
                }
                
                Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
                Write-Host "$($item.Name) installation completed" -ForegroundColor Green
            }

            # Auto Clicker/TinyTask automation
            if ($item.Name -match '3\. Auto Clicker|6\. TinyTask') {
                $automationPath = "C:\Program Files\Automation"
                if (-not (Test-Path $automationPath)) { New-Item -Path $automationPath -ItemType Directory -Force | Out-Null }
                $destination = Join-Path $automationPath $fileName
                Move-Item -Path $file -Destination $destination -Force
                $startMenuPath = [Environment]::GetFolderPath("Programs")
                $shortcutName = ($item.Name -replace '^\d+\. ').Trim() + ".lnk"
                $shell = New-Object -ComObject WScript.Shell
                $shortcut = $shell.CreateShortcut((Join-Path $startMenuPath $shortcutName))
                $shortcut.TargetPath = $destination
                $shortcut.Save()
                Write-Host "Moved to $automationPath and added to Start Menu" -ForegroundColor Green
            }

        } catch {
            Write-Host "Failed: $_" -ForegroundColor Red
        }
    }
}
