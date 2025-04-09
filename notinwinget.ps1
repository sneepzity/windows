#Requires -Version 5.1 # Requires PowerShell 5.1+ for Invoke-WebRequest enhancements & PSCustomObject syntax clarity
# Potentially Requires -RunAsAdministrator

#region --- Wallpaper Download ---

Write-Host "--- Task 1: Downloading Wallpapers ---" -ForegroundColor Cyan

try {
    # Define and Create Wallpaper Folder Path
    $picturesPath = [Environment]::GetFolderPath('MyPictures')
    $wallpaperFolder = Join-Path -Path $picturesPath -ChildPath 'Wallpapers'
    if (-not (Test-Path -Path $wallpaperFolder -PathType Container)) {
        Write-Host "Creating folder: '$wallpaperFolder'"
        New-Item -ItemType Directory -Path $wallpaperFolder -Force | Out-Null
    } else {
         Write-Host "Wallpapers folder already exists: '$wallpaperFolder'"
    }
    Write-Host "Downloading wallpapers to '$wallpaperFolder'..." -ForegroundColor Green

    # Wallpaper URLs and their desired base names (extension will be added)
    $wallpapers = @{
        'https://s6.imgcdn.dev/YjXrqt.jpg' = 'madoka-creepy'
        'https://s6.imgcdn.dev/YjXx4T.jpg' = 'yosemite'
        'https://s6.imgcdn.dev/YjX20D.png' = 'madoka-circular'
        'https://s6.imgcdn.dev/YjXAd9.jpg' = 'madoka-center'
        'https://s6.imgcdn.dev/YjXZjy.jpg' = 'madoka-standing'
        'https://s6.imgcdn.dev/YjX9P8.jpg' = 'madoka-promotion'
        'https://s6.imgcdn.dev/YjXR92.jpg' = 'nature-nordic-original'
        'https://s6.imgcdn.dev/YjXVJi.jpg' = 'nordic-original'
    }

    # Loop through wallpapers, determine name, download
    foreach ($url in $wallpapers.Keys) {
        $baseName = $wallpapers[$url]
        try {
            $extension = [System.IO.Path]::GetExtension($url) # Includes the dot
            if ([string]::IsNullOrEmpty($extension)) {
                Write-Warning "Could not determine extension for '$url'. Skipping rename logic for this."
                $fileName = $baseName # Fallback, though unlikely for these URLs
            } else {
                 $fileName = $baseName + $extension
            }
            $destinationPath = Join-Path -Path $wallpaperFolder -ChildPath $fileName

            Write-Host "  Downloading '$($url.Split('/')[-1])' as '$fileName'..." # Show original filename part
            # Using -UseBasicParsing can be more reliable in some environments
            Invoke-WebRequest -Uri $url -OutFile $destinationPath -UseBasicParsing -ErrorAction Stop
            Write-Host "  Saved '$fileName'" -ForegroundColor Gray

        } catch {
             Write-Error "  Failed to download or save '$url' as '$fileName': $($_.Exception.Message)"
        }
    }

    Write-Host "Wallpaper download task complete." -ForegroundColor Green

} catch {
    Write-Error "A critical error occurred during the wallpaper download setup: $($_.Exception.Message)"
}

#endregion --- Wallpaper Download ---


#region --- Utility / Driver Download ---

Write-Host "`n--- Task 2: Select Utilities/Drivers to Download ---" -ForegroundColor Cyan

try {
    # Define Downloads Folder Path
    $downloadsPath = [Environment]::GetFolderPath('UserProfile')
    $downloadsPath = Join-Path -Path $downloadsPath -ChildPath 'Downloads'
    
    if (-not (Test-Path -Path $downloadsPath -PathType Container)) {
        Write-Host "Creating Downloads folder: '$downloadsPath'"
        New-Item -ItemType Directory -Path $downloadsPath -Force | Out-Null
    }

    # Define Utilities with updated names, URLs, definitions, and selection state
    $utilities = @(
         [PSCustomObject]@{
             Name = 'Nvidia Driver (572 Series)'
             Url = 'https://us.download.nvidia.com/Windows/572.49/572.49-desktop-win10-win11-64bit-international-dch-whql.exe'
             Definition = 'Nvidia graphics card driver from the 572.xx version series.'
             Selected = $false
         }
         [PSCustomObject]@{
             Name = 'AMD Adrenalin Software Installer'
             Url = 'https://drivers.amd.com/drivers/installer/24.30/whql/amd-software-adrenalin-edition-25.3.1-minimalsetup-250312_web.exe'
             Definition = 'AMD Radeon graphics driver and software suite (Adrenalin Edition Web Setup).'
             Selected = $false
         }
          [PSCustomObject]@{
             Name = 'Auto Clicker (Orphamiel)'
             Url = 'https://sourceforge.net/projects/orphamielautoclicker/files/latest/download'
             Definition = 'Software that simulates automated mouse clicks.'
             Selected = $false
         }
         [PSCustomObject]@{
             Name = 'Explorer Patcher'
             Url = 'https://github.com/valinet/ExplorerPatcher/releases/latest/download/ep_setup.exe'
             Definition = 'Reverts Taskbar/Start Menu/Properties features to Windows 10 style.'
             Selected = $false
         }
         [PSCustomObject]@{
             Name = 'FishStrap (Bloxstrap Fork)'
             Url = 'https://github.com/pizzaboxer/bloxstrap/releases/latest/download/Bloxstrap-Installer.exe'
             Definition = 'Bloxstrap fork with enhanced features and support (Roblox related).'
             Selected = $false
         }
         [PSCustomObject]@{
             Name = 'TinyTask Macro Recorder'
             Url = 'https://www.tinytask.net/downloads/tinytask.exe'
             Definition = 'Simple macro recorder for recording/playing back mouse & keyboard actions.'
             Selected = $false
         }
          [PSCustomObject]@{
             Name = 'Visual C++ AIO Installer'
             Url = 'https://sg1-dl.techpowerup.com/files/x3VC5zbRkJtwGtCoXwalAQ/1744229814/Visual-C-Runtimes-All-in-One-Mar-2025.zip'
             Definition = 'All-In-One package installer for various MS Visual C++ Redistributables.'
             Selected = $false
         }
         [PSCustomObject]@{
             Name = 'Acer Nitro AN515-45 Drivers'
             Url = 'https://drive.google.com/uc?export=download&id=1BWNQRHOtI22mKSy_z3isS5bu1HMgU_0W'
             Definition = 'Driver package specifically for Acer Nitro 5 AN515-45 (Ryzen 9 5900HX / RTX 3070).'
             Selected = $false
         }
    )

    # --- Interactive Selection Loop ---
    $userChoice = ''
    do {
        Clear-Host
        Write-Host "Select utilities/drivers to download to '$downloadsPath':"
        Write-Host "---------------------------------------------------------------------" -ForegroundColor Gray
        for($i=0; $i -lt $utilities.Count; $i++){
            $selectionMarker = if($utilities[$i].Selected){ "[X]" } else { "[ ]" }
            Write-Host "$selectionMarker [$($i+1)] $($utilities[$i].Name)" -ForegroundColor White
            Write-Host "      '-- $($utilities[$i].Definition)" -ForegroundColor Gray
        }
        Write-Host "---------------------------------------------------------------------" -ForegroundColor Gray
        Write-Host "Enter number (1-$($utilities.Count)) to toggle selection." -ForegroundColor Yellow
        Write-Host "Enter 'd' to DOWNLOAD selected items." -ForegroundColor Green
        Write-Host "Enter 'q' to QUIT without downloading utilities." -ForegroundColor Red
        $userChoice = Read-Host "Your choice"

        if ($userChoice -match '^\d+$') {
            $index = [int]$userChoice - 1 # Convert to 0-based index
            if ($index -ge 0 -and $index -lt $utilities.Count) {
                # Toggle the 'Selected' property of the chosen object
                $utilities[$index].Selected = -not $utilities[$index].Selected
            } else {
                 Write-Warning "Invalid number entered. Please enter a number between 1 and $($utilities.Count)."
                 Start-Sleep -Seconds 2
            }
        } elseif ($userChoice -eq 'd') {
             # Break loop to proceed to download
             Write-Host "Proceeding to download..." -ForegroundColor Green
        } elseif ($userChoice -eq 'q') {
             Write-Host "Quitting utility download section as requested." -ForegroundColor Yellow
             # Optional: exit the entire script here if desired using 'exit' or 'return'
        } else {
             Write-Warning "Invalid input. Please enter a number, 'd', or 'q'."
             Start-Sleep -Seconds 2
        }

    } while ($userChoice -ne 'd' -and $userChoice -ne 'q') # Loop until download or quit

    # --- Download Selected Utilities (only if user chose 'd') ---
    if ($userChoice -eq 'd') {
        $selectedUtilities = $utilities | Where-Object { $_.Selected -eq $true }

        if ($selectedUtilities.Count -eq 0) {
            Write-Host "No utilities were selected for download." -ForegroundColor Yellow
        } else {
            Write-Host "`nDownloading $($selectedUtilities.Count) selected item(s) to '$downloadsPath'..." -ForegroundColor Green

            # Ensure BITS module is available
            Import-Module BitsTransfer -ErrorAction SilentlyContinue
            if (-not (Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue)) {
                Write-Host "BITS Transfer module not available. Using Invoke-WebRequest as fallback." -ForegroundColor Yellow
                
                foreach ($util in $selectedUtilities) {
                    $fileName = [System.IO.Path]::GetFileName($util.Url)
                    if ([string]::IsNullOrEmpty($fileName) -or $fileName -notmatch '\.(exe|zip|msi)$') {
                        $fileName = "$($util.Name -replace '[^\w\-]', '_').exe"
                    }
                    $destinationPath = Join-Path -Path $downloadsPath -ChildPath $fileName
                    
                    Write-Host "  Downloading '$($util.Name)' as '$fileName'..."
                    try {
                        Invoke-WebRequest -Uri $util.Url -OutFile $destinationPath -UseBasicParsing -ErrorAction Stop
                        Write-Host "    Download complete for '$($util.Name)'." -ForegroundColor Green
                    } catch {
                        Write-Error "    Download FAILED for '$($util.Name)': $($_.Exception.Message)"
                    }
                }
            } else {
                foreach ($util in $selectedUtilities) {
                    # Extract filename from URL or use fallback
                    $fileName = [System.IO.Path]::GetFileName($util.Url)
                    if ([string]::IsNullOrEmpty($fileName) -or $fileName -notmatch '\.(exe|zip|msi)$') {
                        $fileName = "$($util.Name -replace '[^\w\-]', '_').exe"
                    }
                    $destinationPath = Join-Path -Path $downloadsPath -ChildPath $fileName
                    
                    Write-Host "  Starting download for '$($util.Name)' as '$fileName'..."

                    try {
                        $job = Start-BitsTransfer -Source $util.Url -Destination $destinationPath `
                               -DisplayName "Downloading $($util.Name)" -Priority Normal `
                               -Description $util.Definition -ErrorAction Stop -Asynchronous

                        Write-Host "    Transfer Job started (ID: $($job.JobId)). Waiting for completion..." -ForegroundColor Gray

                        # Wait for the job to finish
                        do {
                            $job = Get-BitsTransfer -JobId $job.JobId
                            if ($job.BytesTotal -gt 0) {
                                $percentComplete = [math]::Round(($job.BytesTransferred / $job.BytesTotal) * 100)
                                Write-Progress -Activity "Downloading $($util.Name)" -Status "$($job.JobState) - $percentComplete%" -PercentComplete $percentComplete
                            }
                            Start-Sleep -Seconds 1
                        } while ($job.JobState -eq 'Transferring' -or $job.JobState -eq 'Connecting' -or $job.JobState -eq 'Queued')
                        
                        Write-Progress -Activity "Downloading $($util.Name)" -Completed

                        # Check final job state
                        Switch ($job.JobState) {
                            'Transferred' {
                                Complete-BitsTransfer $job
                                Write-Host "    Download complete for '$($util.Name)'." -ForegroundColor Green
                            }
                            'Error' {
                                $errorDetails = $job | Select-Object -ExpandProperty Error
                                Write-Error "    BITS download FAILED for '$($util.Name)'. Error: $($errorDetails.ErrorDescription)"
                                Remove-BitsTransfer $job
                            }
                            'Cancelled' {
                               Write-Warning "    BITS download CANCELLED for '$($util.Name)'."
                               Remove-BitsTransfer $job
                            }
                            default {
                               Write-Warning "    BITS job for '$($util.Name)' ended in unexpected state: '$($job.JobState)'."
                               Remove-BitsTransfer $job -ErrorAction SilentlyContinue
                            }
                        }
                    } catch {
                        Write-Error "  Failed to download '$($util.Name)': $($_.Exception.Message)"
                        # If a job was created, clean it up
                        if ($job) { Remove-BitsTransfer $job -ErrorAction SilentlyContinue }
                        
                        # Fallback to Invoke-WebRequest
                        Write-Host "  Attempting fallback download method..." -ForegroundColor Yellow
                        try {
                            Invoke-WebRequest -Uri $util.Url -OutFile $destinationPath -UseBasicParsing -ErrorAction Stop
                            Write-Host "    Fallback download complete for '$($util.Name)'." -ForegroundColor Green
                        } catch {
                            Write-Error "    Fallback download FAILED for '$($util.Name)': $($_.Exception.Message)"
                        }
                    }
                } # End foreach utility loop

                Write-Host "`nSelected utility download jobs have been processed." -ForegroundColor Green
                Write-Host "Please check your '$downloadsPath' folder."
            }
        }
    }

} catch {
     Write-Error "A critical error occurred during the utility download section: $($_.Exception.Message)"
}

#endregion --- Utility / Driver Download ---

Write-Host "`n--- Script Finished ---" -ForegroundColor Cyan