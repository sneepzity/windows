# Set execution policy for current process
Set-ExecutionPolicy Bypass -Scope Process -Force

# Install Scoop if missing
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Scoop..."
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    Invoke-Expression (New-Object System.Net.WebClient).DownloadString('https://get.scoop.sh')
}

# Add main bucket if not already added
$installedBuckets = scoop bucket list
if ($installedBuckets -notcontains 'main') {
    Write-Host "Adding main bucket to Scoop..."
    scoop bucket add main
}

# Install requested packages
Write-Host "Installing applications..."
scoop install neovim aria2 git python nodejs

# Verify installations
$requiredPackages = @(
    @{ Name = "Neovim";    Executable = "nvim.exe" },
    @{ Name = "Aria2";     Executable = "aria2c.exe" },
    @{ Name = "Git";       Executable = "git.exe" },
    @{ Name = "Python";    Executable = "python.exe" },
    @{ Name = "Node.js";   Executable = "node.exe" }
)
foreach ($pkg in $requiredPackages) {
    $exe = $pkg.Executable
    if (-not (Get-Command $exe -ErrorAction SilentlyContinue)) {
        Write-Host "$($pkg.Name) installation failed. Exiting..." -ForegroundColor Red
        exit 1
    }
}

# Force environment refresh
Write-Host "Refreshing environment variables..."
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + 
            ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Setup LazyVim configuration
$nvimPath = "$env:LOCALAPPDATA\nvim"
if (-not (Test-Path $nvimPath)) {
    New-Item -Path $nvimPath -ItemType Directory -Force | Out-Null
}
Write-Host "Cloning LazyVim configuration..."
git clone https://github.com/LazyVim/starter $nvimPath --depth 1

Write-Host "Installation complete. Use 'scoop list' to verify installed applications."
