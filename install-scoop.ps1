# Scoop Installer Script - Runs at user level (non-elevated)

# Set execution policy for current user
Write-Host "Setting execution policy to RemoteSigned for current user..." -ForegroundColor Cyan
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

# Install Scoop
Write-Host "Installing Scoop package manager..." -ForegroundColor Cyan
try {
    Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
    
    # Add required buckets
    Write-Host "Adding additional Scoop buckets..." -ForegroundColor Cyan
    
    Write-Host "  - Adding extras bucket" -ForegroundColor Yellow
    scoop bucket add extras
    
    Write-Host "  - Adding nonportable bucket" -ForegroundColor Yellow
    scoop bucket add nonportable
    
    Write-Host "  - Adding games bucket" -ForegroundColor Yellow
    scoop bucket add games
    
    Write-Host "  - Adding nerd-fonts bucket" -ForegroundColor Yellow
    scoop bucket add nerd-fonts
    
    Write-Host "  - Adding versions bucket" -ForegroundColor Yellow
    scoop bucket add versions

    
    Write-Host "Scoop installation and bucket configuration completed successfully!" -ForegroundColor Green
} catch {
    Write-Error "An error occurred during Scoop installation: $($_.Exception.Message)"
    exit 1
}

# Keep the window open
Write-Host "`nPress Enter to exit..." -ForegroundColor Yellow
Read-Host
