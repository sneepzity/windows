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

# Software list with new entries
$software = @(
    [PSCustomObject]@{ Name = '1. Nvidia Driver'; Url = 'https://us.download.nvidia.com/Windows/572.83/572.83-desktop-win10-win11-64bit-international-dch-whql.exe' },
    [PSCustomObject]@{ Name = '2. AMD Adrenalin'; Url = 'https://www.dropbox.com/scl/fi/2cl99uln2bd1wjxisq32t/amd-software-adrenalin-edition-25.3.1-minimalsetup-250312_web.exe?rlkey=78wlc3ociptyhou8rogvnxlax&st=tyosznrf&dl=1' },
    [PSCustomObject]@{ Name = '3. Auto Clicker'; Url = 'https://www.dropbox.com/scl/fi/pel2m2ye2g1ek1j7uet0y/AutoClicker-3.1.exe?rlkey=jjoak7251ls18iwbkdel6l17h&st=mjihmheu&dl=1' },
    [PSCustomObject]@{ Name = '4. Explorer Patcher'; Url = 'https://github.com/valinet/ExplorerPatcher/releases/latest/download/ep_setup.exe' },
    [PSCustomObject]@{ Name = '5. FishStrap'; Url = 'https://github.com/fishstrap/fishstrap/releases/download/v2.9.1.1/Fishstrap-v2.9.1.1.exe' },
    [PSCustomObject]@{ Name = '6. TinyTask'; Url = 'https://github.com/frankwick/t/raw/main/tinytask.exe' },
    [PSCustomObject]@{ Name = '7. VC++ AIO'; Url = 'https://sg1-dl.techpowerup.com/files/x3VC5zbRkJtwGtCoXwalAQ/1744229814/Visual-C-Runtimes-All-in-One-Mar-2025.zip' },
    [PSCustomObject]@{ Name = '8. Acer Nitro Drivers'; Url = 'https://www.dropbox.com/scl/fi/v0v5u245sj7wjhxsta6hh/Acer-Drivers.zip?rlkey=b6rpezg96beecx42dtcmm542a&st=22eh99xl&dl=1' },
    [PSCustomObject]@{ Name = '9. AltDrag'; Url = 'https://github.com/stefansundin/altdrag/releases/download/v1.1/AltDrag-1.1.exe' },
    [PSCustomObject]@{ Name = '10. Cursor'; Url = 'https://downloads.cursor.com/production/7801a556824585b7f2721900066bc87c4a09b743/win32/x64/user-setup/CursorUserSetup-x64-0.48.8.exe' }
)

# Add registry tweak download
$regUrl = 'https://www.tenforums.com/attachments/tutorials/109908d1479010654-startup-delay-enable-disable-windows-10-a-disable_startup_delay.reg'
$regFile = "$env:TEMP\disable_startup_delay.reg"

try {
    Write-Host "Downloading registry tweak..."
    Invoke-WebRequest -Uri $regUrl -OutFile $regFile -ErrorAction Stop
    Start-Process regedit.exe -ArgumentList "/s `"$regFile`"" -Wait
    Remove-Item $regFile -Force -ErrorAction SilentlyContinue
    Write-Host "Registry tweak applied successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to apply registry tweak: $_" -ForegroundColor Red
}

Write-Host "`nAvailable software:"
$software | ForEach-Object { Write-Host $_.Name }

$selection = Read-Host "`nEnter numbers separated by commas (1-10)"
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

            # Explorer Patcher Defender exclusions
            if ($item.Name -eq '4. Explorer Patcher') {
                Add-MpPreference -ExclusionPath "C:\Program Files\ExplorerPatcher"
                Add-MpPreference -ExclusionPath "$env:APPDATA\ExplorerPatcher"
                Add-MpPreference -ExclusionPath "C:\Windows\dxgi.dll"
                Add-MpPreference -ExclusionPath "C:\Windows\SystemApps\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy"
                Add-MpPreference -ExclusionPath "C:\Windows\SystemApps\ShellExperienceHost_cw5n1h2txyewy"
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

            # AltDrag installation and startup configuration
            if ($item.Name -eq '9. AltDrag') {
                Start-Process -FilePath $file -ArgumentList "/S" -Wait
                Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
                $startupPath = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
                $shortcutPath = Join-Path $startupPath "AltDrag.lnk"
                $shell = New-Object -ComObject WScript.Shell
                $shortcut = $shell.CreateShortcut($shortcutPath)
                $shortcut.TargetPath = "C:\Program Files\AltDrag\altdrag.exe"
                $shortcut.Save()
                Write-Host "AltDrag installed and added to startup" -ForegroundColor Green
            }

            # Cursor installation
            if ($item.Name -eq '10. Cursor') {
                Start-Process -FilePath $file -ArgumentList "/S" -Wait
                Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
                Write-Host "Cursor installed silently" -ForegroundColor Green
            }

        } catch {
            Write-Host "Failed: $_" -ForegroundColor Red
        }
    }
}
