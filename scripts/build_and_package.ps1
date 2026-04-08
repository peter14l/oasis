# build_and_package.ps1
# Morrow — Secure Build Script for Oasis (v3.0)
# Refactor: Native output for reliability; eliminates "Initializing" hang.

#region ── Config ──────────────────────────────────────────────────────────────
$ENV_FILE = ".env"
$WORKING_DIR = Get-Location
$APP_NAME = "Oasis"
#endregion

#region ── Helpers ─────────────────────────────────────────────────────────────
function Write-Header($text) {
    Write-Host "`n  ╔══════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "  ║  $($text.PadRight(52))║" -ForegroundColor Cyan
    Write-Host "  ╚══════════════════════════════════════════════════════╝`n" -ForegroundColor DarkCyan
}

function Write-Step($text, $color = "White") { Write-Host "  ► $text" -ForegroundColor $color }
function Write-Success($text) { Write-Host "  ✔ $text" -ForegroundColor Green }
function Write-Fail($text) { Write-Host "  ✘ $text" -ForegroundColor Red }

function Send-Notification {
    param([string]$Title, [string]$Message, [bool]$IsError = $false)
    if ($IsError) { [System.Console]::Beep(440, 500) } 
    else { [System.Console]::Beep(880, 200); [System.Console]::Beep(1100, 200) }

    Add-Type -AssemblyName System.Windows.Forms
    $noti = New-Object System.Windows.Forms.NotifyIcon
    $noti.Icon = [System.Drawing.Icon]::ExtractAssociatedIcon((Get-Process -id $pid).Path)
    $noti.BalloonTipIcon = if ($IsError) { "Error" } else { "Info" }
    $noti.BalloonTipText = $Message
    $noti.BalloonTipTitle = $Title
    $noti.Visible = $true
    $noti.ShowBalloonTip(5000)
}

function Stop-BuildProcesses {
    Write-Step "Cleaning up stale build processes..." "DarkGray"
    $processes = @("java", "dart", "flutter")
    foreach ($p in $processes) {
        $found = Get-Process -Name $p -ErrorAction SilentlyContinue
        if ($found) {
            Write-Host "  ► Terminating $($found.Count) $p processes..." -ForegroundColor DarkGray
            Stop-Process -Name $p -Force -ErrorAction SilentlyContinue
        }
    }
    Write-Success "Workspace cleared"
}

function Invoke-BuildStep {
    param($Title, $Command, $Arguments)
    Write-Step "$Title..." "Cyan"
    
    # Run the command directly to allow native colors and progress bars
    if ($Arguments) {
        & $Command $Arguments
    } else {
        & $Command
    }

    if ($LASTEXITCODE -ne 0) {
        Write-Fail "$Title failed."
        return $LASTEXITCODE
    }
    Write-Success "$Title complete."
    return 0
}
#endregion

#region ── Execution ───────────────────────────────────────────────────────────
Write-Header "MORROW  BUILD  PIPELINE"

# Ensure environment variables are clear
Stop-BuildProcesses

$FlutterCmd = Get-Command flutter -ErrorAction SilentlyContinue
if (-not $FlutterCmd) { Write-Fail "Flutter not found."; exit 1 }
$FLUTTER_PATH = $FlutterCmd.Source

if (-not (Test-Path $ENV_FILE)) { Write-Fail ".env missing."; exit 1 }
Write-Success ".env found for $APP_NAME"

# Step 0: Cleanup & Dependencies
Write-Header "Step 0: Workspace Cleanup"
Invoke-BuildStep -Title "Cleaning workspace" -Command $FLUTTER_PATH -Arguments "clean"
Invoke-BuildStep -Title "Resolving dependencies" -Command $FLUTTER_PATH -Arguments "pub get"

# Step 1: Android
Write-Header "Step 1: Android APK"
$androidArgs = @("build", "apk", "--release", "--split-per-abi", "--no-pub", "--dart-define-from-file=`"$ENV_FILE`"")
$androidExit = Invoke-BuildStep -Title "Android APK Build" -Command $FLUTTER_PATH -Arguments $androidArgs

if ($androidExit -ne 0) {
    Send-Notification -Title "Build Failed" -Message "Android build for $APP_NAME failed." -IsError $true
    exit $androidExit
}

# Step 2: Windows
Write-Header "Step 2: Windows Build"
$windowsArgs = @("build", "windows", "--release", "--no-pub", "--dart-define-from-file=`"$ENV_FILE`"")
$windowsExit = Invoke-BuildStep -Title "Windows Release Build" -Command $FLUTTER_PATH -Arguments $windowsArgs

if ($windowsExit -eq 0) {
    Write-Header "Step 3: Packaging"
    Write-Step "Creating MSIX package..." "Yellow"
    dart run msix:create --build-windows false
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Packaging complete."
        if (Test-Path "test_certificate.pfx") {
            Write-Success "Certificate generated: test_certificate.pfx"
            Write-Step "You can install this manually or use: certutil -addstore -f 'Root' 'test_certificate.pfx'" "DarkGray"
        }
        Send-Notification -Title "Build Success" -Message "Oasis is ready!"
    } else {
        Write-Fail "MSIX creation failed."
        Send-Notification -Title "Build Failed" -Message "MSIX creation for $APP_NAME failed." -IsError $true
    }
} else {
    Send-Notification -Title "Build Failed" -Message "Windows build for $APP_NAME failed." -IsError $true
}

Write-Header "PIPELINE FINISHED"
#endregion