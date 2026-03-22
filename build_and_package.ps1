# build_and_package.ps1
# A simple colored TUI script for Flutter + Dart packaging

# Clear the screen
Clear-Host

# Function to print colored banners
function Show-Message($text, $color) {
    Write-Host "=====================================" -ForegroundColor $color
    Write-Host $text -ForegroundColor $color
    Write-Host "=====================================" -ForegroundColor $color
}

# Step 1: Flutter build
Show-Message "🚀 Starting Flutter build (APK Release, split per ABI)..." Cyan
flutter build apk --release --split-per-abi

if ($LASTEXITCODE -eq 0) {
    Show-Message "✅ Flutter build completed successfully!" Green
} else {
    Show-Message "❌ Flutter build failed. Exiting..." Red
    exit $LASTEXITCODE
}

# Step 2: Dart MSIX packaging
Show-Message "📦 Creating MSIX package with Dart..." Yellow
dart run msix:create

if ($LASTEXITCODE -eq 0) {
    Show-Message "🎉 MSIX package created successfully!" Green
} else {
    Show-Message "❌ MSIX packaging failed." Red
    exit $LASTEXITCODE
}

Show-Message "✨ All tasks finished!" Magenta
