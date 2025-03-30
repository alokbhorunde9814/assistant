# PowerShell script to set up Firebase using Firebase CLI

Write-Host "Firebase CLI Setup Helper" -ForegroundColor Cyan
Write-Host "=========================" -ForegroundColor Cyan
Write-Host ""

# Check if Node.js is installed
$nodeInstalled = $null
try {
    $nodeInstalled = Get-Command node -ErrorAction SilentlyContinue
} catch {}

if ($null -eq $nodeInstalled) {
    Write-Host "Node.js is not installed or not in PATH. Please install Node.js first." -ForegroundColor Red
    Write-Host "Download from: https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}

# Check if Firebase CLI is installed
$firebaseInstalled = $null
try {
    $firebaseInstalled = Get-Command firebase -ErrorAction SilentlyContinue
} catch {}

if ($null -eq $firebaseInstalled) {
    Write-Host "Installing Firebase CLI..." -ForegroundColor Yellow
    npm install -g firebase-tools
} else {
    Write-Host "Firebase CLI is already installed." -ForegroundColor Green
}

# Log in to Firebase
Write-Host ""
Write-Host "Logging in to Firebase..." -ForegroundColor Yellow
firebase login

# Check if FlutterFire CLI is installed
Write-Host ""
Write-Host "Checking FlutterFire CLI..." -ForegroundColor Yellow
$flutterfireInstalled = $false
try {
    $result = dart pub global list | Select-String "flutterfire_cli"
    if ($result) {
        $flutterfireInstalled = $true
        Write-Host "FlutterFire CLI is already installed." -ForegroundColor Green
    }
} catch {}

if (-not $flutterfireInstalled) {
    Write-Host "Installing FlutterFire CLI..." -ForegroundColor Yellow
    dart pub global activate flutterfire_cli
}

# Configure Firebase for the Flutter project
Write-Host ""
Write-Host "Configuring Firebase for your Flutter project..." -ForegroundColor Yellow
Write-Host "This will walk you through selecting a Firebase project and platforms to configure." -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Enter to continue or Ctrl+C to cancel..." -ForegroundColor Cyan
Read-Host

# Run FlutterFire configure
flutterfire configure

Write-Host ""
Write-Host "Firebase configuration complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Make sure your main.dart file initializes Firebase with DefaultFirebaseOptions" -ForegroundColor White
Write-Host "2. Go to the Firebase Console and enable the Authentication methods you need" -ForegroundColor White
Write-Host "3. Run 'flutter clean && flutter pub get' to ensure everything is updated" -ForegroundColor White
Write-Host "4. Run 'flutter run' to test your app" -ForegroundColor White
Write-Host ""
Write-Host "Press Enter to exit..." -ForegroundColor Cyan
Read-Host 