# ─────────────────────────────────────────────────────────────────────────────
#  $TestMode: set to $true to exercise this script against a throwaway distro
#  without touching the real work environment. When $true it:
#    • targets the Ubuntu-Claude distro instead of Ubuntu-CFIS
#    • uses hardcoded WSL credentials (claude/claude) instead of prompting
#    • skips the admin check, the slow Windows installs (git, WSL components,
#      wezterm) and the copy of .wezterm.lua into the profile
#  SHIP WITH $TestMode = $false.
# ─────────────────────────────────────────────────────────────────────────────
$TestMode = $false

$desiredDistro = if ($TestMode) { "CFIS-Claude" } else { "Ubuntu-CFIS" }
$userHome      = $env:USERPROFILE

Set-Location $userHome

# Check for administrator privileges (skipped in test mode, which does no
# machine-wide installs).
if (-not $TestMode) {
    if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
        [Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Warning "This script must be run as Administrator."
        exit 1
    }
}

if ($TestMode) {
    Write-Host ""
    Write-Host "  [ TEST MODE ] target distro: $desiredDistro" -ForegroundColor Magenta
    Write-Host "  Windows installs + admin check skipped; credentials hardcoded." -ForegroundColor Magenta
    Write-Host ""
}

if (-not $TestMode) {
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

    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Host "Git already installed ($(git --version)). Skipping." -ForegroundColor Green
    } else {
        Write-Host "Installing git..."
        winget install -e --id Git.Git
    }

    Write-Host "Installing WSL2 components..."
    wsl --set-default-version 2
    wsl --install --web-download --no-distribution
    wsl --update --web-download

    Write-Host "Please ensure the success of the above WSL2 install before continuing... "
    Read-Host -Prompt "Press Enter to continue"
}

$installedDistros = wsl --list --quiet

if ($installedDistros -contains $desiredDistro) {
    Write-Host "$desiredDistro is already installed. Skipping install." -ForegroundColor Green
}
else {
    Write-Host "Installing $desiredDistro..." -ForegroundColor Yellow
    wsl --install -d Ubuntu-24.04 --name $desiredDistro --no-launch
    Write-Host ""
    Write-Host "$desiredDistro registered successfully!" -ForegroundColor Green
}

if (-not $TestMode) {
    Write-Host ""
    Write-Host "Installing wezterm..."
    winget install -e --id wez.wezterm
}

Write-Host "Cloning config repo into home"
Set-Location $userHome
if (Test-Path "configs") {
    Write-Host "configs folder already exists, skipping clone" -ForegroundColor Yellow
} else {
    git clone https://github.com/theonlyguills/configs
}

if (-not $TestMode) {
    Write-Host "Copying wezterm defaults... "
    Copy-Item -Path configs\.wezterm.lua -Destination $userHome\.wezterm.lua -Force
}

# ─────────────────────────────────────────────────────────────────────────────
#  Provision the WSL user deterministically, as root, on the freshly-registered
#  (uninitialized) distro. This runs before any interactive launch, so Ubuntu's
#  OOBE (username/password prompt) never fires.
# ─────────────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Provisioning WSL user" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

if ($TestMode) {
    Write-Host "[TestMode] Using hardcoded WSL credentials claude/claude" -ForegroundColor Magenta
    $wslUser = "claude"
    $wslPass = "claude"
} else {
    $cred    = Get-Credential -Message "Choose your WSL username & password"
    $wslUser = $cred.UserName
    $wslPass = $cred.GetNetworkCredential().Password
}

Write-Host "Creating user '$wslUser' as root..." -ForegroundColor Yellow

# Create the account, grant sudo, set it as the distro default user, and drop in
# a TEMPORARY passwordless-sudo rule so the unattended apt/curl steps in
# bootstrap.sh don't stall waiting for a password. The rule is removed below.
$provision = @"
set -e
useradd -m -s /bin/bash '$wslUser'
usermod -aG sudo '$wslUser'
printf '[boot]\nsystemd=true\n\n[user]\ndefault=%s\n' '$wslUser' > /etc/wsl.conf
echo '$wslUser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/99-bootstrap
chmod 440 /etc/sudoers.d/99-bootstrap
"@
wsl -d $desiredDistro -u root bash -c $provision
if ($LASTEXITCODE -ne 0) {
    Write-Host "User provisioning failed" -ForegroundColor Red
    Read-Host -Prompt "Press Enter to exit"; exit 1
}

# Set the password via a UTF-8 (no BOM) temp file that chpasswd reads. The
# password is never interpolated into a shell command line (so $, ", backtick
# etc. are safe), AND we control the exact bytes: piping through wsl's stdin can
# fall back to the legacy console code page and corrupt non-ASCII characters
# (accents, etc.), which then don't match what you type at a UTF-8 prompt.
$pwFile    = Join-Path $env:TEMP ("wslpw_" + [System.Guid]::NewGuid().ToString("N"))
[System.IO.File]::WriteAllText($pwFile, ("{0}:{1}`n" -f $wslUser, $wslPass), (New-Object System.Text.UTF8Encoding $false))
$pwFileWsl = (wsl -d $desiredDistro wslpath -a ($pwFile -replace '\\','/')).Trim()
wsl -d $desiredDistro -u root bash -c "chpasswd < '$pwFileWsl'"
$pwExit    = $LASTEXITCODE
Remove-Item $pwFile -Force -ErrorAction SilentlyContinue
if ($pwExit -ne 0) {
    Write-Host "Setting password failed" -ForegroundColor Red
    Read-Host -Prompt "Press Enter to exit"; exit 1
}

# Apply /etc/wsl.conf so the default user takes effect on the next start.
wsl --terminate $desiredDistro

# ─────────────────────────────────────────────────────────────────────────────
#  Stage bootstrap.sh into WSL and run it synchronously, as the user. The path
#  is resolved with wslpath (no hardcoded /mnt/c), so it works regardless of
#  where the Windows profile actually lives.
# ─────────────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  Running Automated Linux Setup" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Use forward slashes: backslashes get stripped passing through wsl.exe args.
$winScriptFwd = ($userHome -replace '\\','/') + '/configs/bootstrap.sh'
$wslScript = (wsl -d $desiredDistro wslpath -a "$winScriptFwd").Trim()
wsl -d $desiredDistro -u $wslUser bash -c "cp '$wslScript' ~/bootstrap.sh && sed -i 's/\r`$//' ~/bootstrap.sh && chmod +x ~/bootstrap.sh"

# Verify it landed (errors are NOT silenced).
wsl -d $desiredDistro -u $wslUser bash -c "test -f ~/bootstrap.sh"
if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to stage bootstrap.sh" -ForegroundColor Red
    Read-Host -Prompt "Press Enter to exit"; exit 1
}
Write-Host "bootstrap.sh staged." -ForegroundColor Green

# Run it in this window — visible output, real exit code.
wsl -d $desiredDistro -u $wslUser bash -c "bash ~/bootstrap.sh"
$bootstrapExit = $LASTEXITCODE
if ($bootstrapExit -ne 0) {
    Write-Host "Bootstrap failed (exit $bootstrapExit)" -ForegroundColor Red
}

# Remove the temporary passwordless-sudo rule.
wsl -d $desiredDistro -u root rm -f /etc/sudoers.d/99-bootstrap

# ─────────────────────────────────────────────────────────────────────────────
#  Open WezTerm for normal use. No auto-run, no .bashrc injection — the distro
#  is already fully provisioned and opens as the created user.
# ─────────────────────────────────────────────────────────────────────────────
Write-Host ""
$weztermPath = "C:\Program Files\WezTerm\wezterm.exe"
if (Test-Path $weztermPath) {
    Start-Process -FilePath $weztermPath -ArgumentList "start"
    Write-Host "WezTerm launched." -ForegroundColor Green
} else {
    Write-Host "WezTerm not found at $weztermPath." -ForegroundColor Yellow
    Write-Host "Open your shell with:  wsl -d $desiredDistro" -ForegroundColor Yellow
}

if ($bootstrapExit -eq 0) {
    Write-Host ""
    Write-Host "Setup complete - usable shell as '$wslUser' in $desiredDistro." -ForegroundColor Green
}
