# Elevate to admin if not already
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Set execution policy for current process
Set-ExecutionPolicy Bypass -Scope Process -Force

# Install .NET 4.0 if missing
$dotNetInstalled = $false
try {
    $release = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' -ErrorAction Stop).Release
    if ($release -ge 30319) { $dotNetInstalled = $true }
} catch {}

if (-not $dotNetInstalled) {
    Write-Host "Installing .NET Framework 4.0..."
    $dotNetUrl = "https://download.microsoft.com/download/9/5/A/95A9616B-7A37-4AF6-BC36-D6EA96C8DAAE/dotNetFx40_Full_x86_x64.exe"
    $installerPath = "$env:TEMP\dotnet40.exe"
    Invoke-WebRequest -Uri $dotNetUrl -OutFile $installerPath
    Start-Process -FilePath $installerPath -ArgumentList "/q /norestart" -Wait
    Remove-Item -Path $installerPath -Force
}

# Install Chocolatey if missing
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..."
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

# Install requested packages
Write-Host "Installing applications..."
choco install neovim aria2 git python nodejs -y --force  # Added python and nodejs [[3]][[5]]

# Verify installations [[1]][[7]]
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

# Force environment refresh [[6]]
Write-Host "Refreshing environment variables..."
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + 
            ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

# Setup LazyVim configuration
$nvimPath = "$env:LOCALAPPDATA\nvim"
if (-not (Test-Path $nvimPath)) {
    New-Item -Path $nvimPath -ItemType Directory -Force | Out-Null
}

Write-Host "Cloning LazyVim configuration..."
git clone https://github.com/LazyVim/starter $nvimPath --depth 1  # Use explicit path [[5]][[9]]

Write-Host "Installation complete. Use 'choco list --local-only' to verify."
