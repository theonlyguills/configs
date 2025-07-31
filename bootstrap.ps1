$removeGit = $true
$desiredDistro = "Ubuntu-CFIS"
$profile = $env:USERPROFILE

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
    Write-Host "Ubuntu installed. On first launch it will ask you to set up your username and password. "
    Read-Host -Prompt "Press Enter to continue"
}

Write-Host "Installing wezterm..."
winget install -e --id wez.wezterm

Write-Host "Cloning config repo into home"
Set-Location "$env:USERPROFILE"
git clone https://github.com/theonlyguills/configs

Write-Host "Copying wezterm defaults... "
Copy-Item -Path configs\.wezterm.lua -Destination $profile\.wezterm.lua -Force


Write-Host ""
Write-Host "Launching Ubuntu, once you get to the command prompt, type exit to come back here." -ForegroundColor Red
Read-Host -Prompt "Press Enter to continue"
Start-Process wezterm.exe

Read-Host -Prompt "AFTER your user and password is entered in WSL, and you exited, press Enter to continue"

Copy-Item -Path configs\bootstrap.sh -Destination "\\wsl$\Ubuntu-CFIS\tmp\bootstrap.sh" -Force
wsl -d $desiredDistro cp /tmp/bootstrap.sh ~
wsl -d $desiredDistro chmod +x ~/bootstrap.sh

Read-Host -Prompt "wezterm will launch again. at the terminal, launch ~/bootstrap.sh. press Enter to continue"
Start-Process wezterm.exe
