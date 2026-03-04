# Test script for bootstrap.sh launch mechanism
# Run this to test the WezTerm launch without running full bootstrap.ps1

$desiredDistro = "Ubuntu-CFIS"

Write-Host ""
Write-Host "Testing bootstrap script launch..." -ForegroundColor Yellow
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
Write-Host "Launching WezTerm with bootstrap script..." -ForegroundColor Yellow
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
    # Add a one-time command to .bashrc that will run bootstrap.sh
    Write-Host "Adding bootstrap auto-run to .bashrc..." -ForegroundColor Yellow
    
    # Copy the script and convert line endings with dos2unix
    wsl -d $desiredDistro bash -c "cp /mnt/c/Users/$env:USERNAME/configs/add-bootstrap-to-bashrc.sh /tmp/ && dos2unix /tmp/add-bootstrap-to-bashrc.sh 2>/dev/null && bash /tmp/add-bootstrap-to-bashrc.sh"
    
    Write-Host "Launching WezTerm (bootstrap will run automatically)..." -ForegroundColor Yellow
    # Just launch WezTerm - it will use the default distro from .wezterm.lua
    # If testing with a different distro, update .wezterm.lua first or manually launch
    Start-Process -FilePath $weztermPath -ArgumentList "start"
    
    Write-Host ""
    Write-Host "NOTE: WezTerm will open with the default distro configured in .wezterm.lua" -ForegroundColor Yellow
    Write-Host "      If testing with $desiredDistro, make sure that's your default distro." -ForegroundColor Yellow
    
    Write-Host ""
    Write-Host "✅ WezTerm launched!" -ForegroundColor Green
    Write-Host ""
    Write-Host "The terminal window should show the bootstrap script running."
    Write-Host "If the window closed immediately, check the error messages above."
} else {
    Write-Host "❌ WezTerm not found at expected location" -ForegroundColor Red
    Write-Host "Please run bootstrap.sh manually in WSL:" -ForegroundColor Yellow
    Write-Host "  wsl -d $desiredDistro" -ForegroundColor Yellow
    Write-Host "  ~/bootstrap.sh" -ForegroundColor Yellow
}

Read-Host -Prompt "Press Enter to exit"
