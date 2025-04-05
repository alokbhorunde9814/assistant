# PowerShell script to get SHA-1 fingerprint for Firebase Google Sign-In

Write-Host "Getting SHA-1 fingerprint for Firebase Google Sign-In..." -ForegroundColor Cyan

# Change to the android directory
Push-Location -Path "android"

try {
    # Run the Gradle task to get the signing report
    Write-Host "Running Gradle signingReport task..." -ForegroundColor Yellow
    ./gradlew signingReport

    Write-Host "`nLook for the 'SHA-1' value in the output above." -ForegroundColor Green
    Write-Host "Copy this value to your Firebase console under Project settings > Your apps > SHA certificate fingerprints." -ForegroundColor Green
}
catch {
    Write-Host "Error running Gradle task: $_" -ForegroundColor Red
}
finally {
    # Return to the original directory
    Pop-Location
}

Write-Host "`nPress Enter to exit..." -ForegroundColor Cyan
Read-Host

# Get SHA-1 fingerprint for debug keystore
Write-Host "Getting SHA-1 fingerprint for debug keystore..."
$debugKey = keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android | Select-String "SHA1:"

if ($debugKey) {
    $sha1 = $debugKey.Line.Split(":")[1].Trim()
    Write-Host "`nDebug SHA-1 fingerprint: $sha1"
    Write-Host "`nPlease add this SHA-1 fingerprint to your Firebase project:"
    Write-Host "1. Go to Firebase Console (https://console.firebase.google.com/)"
    Write-Host "2. Select your project"
    Write-Host "3. Go to Project Settings"
    Write-Host "4. Under 'Your apps', select the Android app"
    Write-Host "5. Click 'Add fingerprint' and paste the SHA-1 above"
} else {
    Write-Host "Could not find SHA-1 fingerprint. Make sure you have the Android SDK installed and the debug keystore exists."
} 