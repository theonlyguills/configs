$removeGit = $true
$desiredDistro = "Ubuntu-CFIS"
$profile = $env:USERPROFILE

Set-Location $profile

# Check for administrator privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Warning "This script must be run as Administrator."
    exit 1
}

Write-Host ""
Write-Host " * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * "
Write-Host ""
Write-Host "Make sure to get latest intel GFX drivers and install them" -ForegroundColor Yellow
Write-Host "using privilege management before running this script." -ForegroundColor Yellow
Write-Host ""
Write-Host " * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * "
Write-Host ""

Write-Host "Available at https://www.intel.com/content/www/us/en/download/19344/intel-graphics-windows-dch-drivers.html"
Write-Host ""

Read-Host -Prompt "Press Enter to continue"

$uninstaller = "C:\Program Files\Git\unins000.exe"

if ($removeGit -And (Test-Path $uninstaller)) {
    Write-Host "Uninstalling old version of Git..."
    Start-Process -FilePath $uninstaller -Wait
    Write-Host "Git has been uninstalled."
}

Write-Host "Installing git..."
winget install -e --id Git.Git

Write-Host "Installing WSL2 components..."
wsl --set-default-version 2
wsl --install --web-download --no-distribution
wsl --update --web-download

Write-Host "Please ensure the success of the above WSL2 install before continuing... "
Read-Host -Prompt "Press Enter to continue"

$installedDistros = wsl --list --quiet

if ($installedDistros -contains $desiredDistro) {
    Write-Host "$desiredDistro is already installed. Skipping install." -ForegroundColor Green
}
else {
    Write-Host "Installing $desiredDistro..." -ForegroundColor Yellow
    wsl --install -d Ubuntu-24.04 --name $desiredDistro --no-launch
    Write-Host ""
    Write-Host "Ubuntu installed successfully!" -ForegroundColor Green
    Write-Host "On first launch, you'll create your username and password." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Installing wezterm..."
winget install -e --id wez.wezterm

Write-Host "Cloning config repo into home"
Set-Location "$env:USERPROFILE"
if (Test-Path "configs") {
    Write-Host "configs folder already exists, skipping clone" -ForegroundColor Yellow
} else {
    git clone https://github.com/theonlyguills/configs
}

Write-Host "Copying wezterm defaults... "
Copy-Item -Path configs\.wezterm.lua -Destination $profile\.wezterm.lua -Force

# Check if WSL user has been created (distro has been initialized)
$userCreated = wsl -d $desiredDistro test -d /home 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "  WSL Initial Setup Required" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "WezTerm will now open for you to create your WSL username and password." -ForegroundColor Yellow
    Write-Host "After creating your account, the window will close automatically." -ForegroundColor Yellow
    Write-Host ""
    Read-Host -Prompt "Press Enter to launch WezTerm for initial setup"
    
    # Launch WezTerm for initial user setup - it will close when setup completes
    $weztermPath = "C:\Program Files\WezTerm\wezterm.exe"
    & $weztermPath start -- wsl -d $desiredDistro
    
    # Wait for user to complete setup
    Write-Host ""
    Write-Host "After you finish creating your user (username and password)," -ForegroundColor Yellow
    Write-Host "the window will close. Then we'll continue with automated setup." -ForegroundColor Yellow
    Read-Host -Prompt "Press Enter after you've created your user and the window closed"
}

Write-Host ""
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Running Automated Linux Setup" -ForegroundColor Cyan  
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Download bootstrap.sh to WSL (simpler and more reliable than wslpath conversion)
Write-Host "Preparing bootstrap script..." -ForegroundColor Yellow

# Try local copy first if configs exists
$localScript = "$env:USERPROFILE\configs\bootstrap.sh"
if (Test-Path $localScript) {
    Write-Host "Using local bootstrap.sh from configs folder..." -ForegroundColor Green
    # Copy directly via WSL file access
    wsl -d $desiredDistro bash -c "cp /mnt/c/Users/$env:USERNAME/configs/bootstrap.sh /tmp/bootstrap.sh 2>/dev/null && cp /tmp/bootstrap.sh ~ && chmod +x ~/bootstrap.sh" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Local copy successful" -ForegroundColor Green
    } else {
        Write-Host "Local copy failed, downloading from GitHub..." -ForegroundColor Yellow
        wsl -d $desiredDistro bash -c "wget -q https://raw.githubusercontent.com/theonlyguills/configs/refs/heads/master/bootstrap.sh -O /tmp/bootstrap.sh && cp /tmp/bootstrap.sh ~ && chmod +x ~/bootstrap.sh"
    }
} else {
    Write-Host "configs folder not found, downloading from GitHub..." -ForegroundColor Yellow
    wsl -d $desiredDistro bash -c "wget -q https://raw.githubusercontent.com/theonlyguills/configs/refs/heads/master/bootstrap.sh -O /tmp/bootstrap.sh && cp /tmp/bootstrap.sh ~ && chmod +x ~/bootstrap.sh"
}

# Verify the script exists
wsl -d $desiredDistro test -f ~/bootstrap.sh
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Failed to prepare bootstrap script" -ForegroundColor Red
    Read-Host -Prompt "Press Enter to exit"
    exit 1
}

Write-Host "✅ Bootstrap script ready" -ForegroundColor Green
Write-Host ""

# Launch wezterm with the bootstrap script
Write-Host "Launching WezTerm to run automated setup..." -ForegroundColor Yellow
$weztermPath = "C:\Program Files\WezTerm\wezterm.exe"

if (Test-Path $weztermPath) {
    # Create a wrapper script in WSL that will run bootstrap and keep shell open
    wsl -d $desiredDistro bash -c @"
cat > /tmp/run-bootstrap.sh << 'INNEREOF'
#!/bin/bash
echo ''
echo '==========================================='
echo 'Running CFIS development environment setup...'
echo '==========================================='
echo ''
if [ -f ~/bootstrap.sh ]; then
    ~/bootstrap.sh
    EXITCODE=\$?
    echo ''
    if [ \$EXITCODE -eq 0 ]; then
        echo '✅ Bootstrap script completed successfully'
    else
        echo '❌ Bootstrap script failed with exit code: '\$EXITCODE
    fi
else
    echo '❌ bootstrap.sh not found in home directory'
fi
echo ''
echo 'Shell will remain open. Press Ctrl+D or type exit to close.'
exec bash
INNEREOF
chmod +x /tmp/run-bootstrap.sh
"@

    # Launch WezTerm with the wrapper script
    # Use -- to separate WezTerm args from the command to execute
    Start-Process -FilePath $weztermPath -ArgumentList "start", "--", "wsl", "-d", "$desiredDistro", "/tmp/run-bootstrap.sh"
    
    Write-Host ""
    Write-Host "✅ WezTerm launched!" -ForegroundColor Green
    Write-Host ""
    Write-Host "The terminal window will run the setup script automatically."
    Write-Host "Follow the prompts in that window to complete the setup."
    Write-Host ""
    Write-Host "This PowerShell window can now be closed." -ForegroundColor Cyan
} else {
    Write-Host "❌ WezTerm not found at expected location" -ForegroundColor Red
    Write-Host "Please run bootstrap.sh manually in WSL:" -ForegroundColor Yellow
    Write-Host "  wsl -d $desiredDistro" -ForegroundColor Yellow
    Write-Host "  ~/bootstrap.sh" -ForegroundColor Yellow
}
