# Test WezTerm launch step by step
$desiredDistro = "Ubuntu-CFIS"
$weztermPath = "C:\Program Files\WezTerm\wezterm.exe"

Write-Host "Testing different WezTerm launch methods..." -ForegroundColor Yellow
Write-Host ""

# First, verify wrapper script exists
Write-Host "1. Checking if wrapper script exists..." -ForegroundColor Cyan
wsl -d $desiredDistro test -f /tmp/run-bootstrap.sh
if ($LASTEXITCODE -eq 0) {
    Write-Host "   ✅ /tmp/run-bootstrap.sh exists" -ForegroundColor Green
} else {
    Write-Host "   ❌ /tmp/run-bootstrap.sh not found, creating it..." -ForegroundColor Yellow
    wsl -d $desiredDistro bash -c @"
cat > /tmp/run-bootstrap.sh << 'EOF'
#!/bin/bash
echo 'Test script running...'
echo 'Press Enter to close'
read
EOF
chmod +x /tmp/run-bootstrap.sh
"@
}

Write-Host ""
Write-Host "2. Test: Running wsl command directly from PowerShell..." -ForegroundColor Cyan
Write-Host "   Command: wsl -d $desiredDistro /tmp/run-bootstrap.sh" -ForegroundColor Gray
Read-Host "   Press Enter to test this"
wsl -d $desiredDistro /tmp/run-bootstrap.sh

Write-Host ""
Write-Host "3. Test: WezTerm with full wsl path..." -ForegroundColor Cyan
Write-Host '   Command: & "$weztermPath" start -- C:\Windows\System32\wsl.exe -d $desiredDistro /tmp/run-bootstrap.sh' -ForegroundColor Gray
Read-Host "   Press Enter to test this"
& $weztermPath start -- C:\Windows\System32\wsl.exe -d $desiredDistro /tmp/run-bootstrap.sh

Write-Host ""
Write-Host "4. Test: WezTerm using cmd.exe wrapper..." -ForegroundColor Cyan
Write-Host '   Command: & "$weztermPath" start -- cmd.exe /c wsl -d $desiredDistro /tmp/run-bootstrap.sh' -ForegroundColor Gray
Read-Host "   Press Enter to test this"
& $weztermPath start -- cmd.exe /c wsl -d $desiredDistro /tmp/run-bootstrap.sh

Write-Host ""
Write-Host "5. Test: Start-Process with full path..." -ForegroundColor Cyan
Write-Host '   Command: Start-Process -FilePath "$weztermPath" -ArgumentList @("start", "--", "C:\Windows\System32\wsl.exe", "-d", "$desiredDistro", "/tmp/run-bootstrap.sh")' -ForegroundColor Gray
Read-Host "   Press Enter to test this"
Start-Process -FilePath $weztermPath -ArgumentList @("start", "--", "C:\Windows\System32\wsl.exe", "-d", "$desiredDistro", "/tmp/run-bootstrap.sh")

Write-Host ""
Write-Host "Testing complete. Did any of these work?" -ForegroundColor Yellow
