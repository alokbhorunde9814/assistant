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