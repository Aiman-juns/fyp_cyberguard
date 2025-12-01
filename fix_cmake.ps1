# Remove corrupted CMake
$cmakePath = "C:\Users\User\AppData\Local\Android\Sdk\cmake\3.22.1"
if (Test-Path $cmakePath) {
    Write-Host "Removing corrupted CMake..."
    Remove-Item $cmakePath -Recurse -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
}

# Also remove any backups
$backupPath = "C:\Users\User\AppData\Local\Android\Sdk\cmake\3.22.1.backup"
if (Test-Path $backupPath) {
    Remove-Item $backupPath -Recurse -Force -ErrorAction SilentlyContinue
}

# Clean Flutter build
Write-Host "Cleaning Flutter build..."
flutter clean

# Run build with verbose output
Write-Host "Running Flutter build..."
flutter run
