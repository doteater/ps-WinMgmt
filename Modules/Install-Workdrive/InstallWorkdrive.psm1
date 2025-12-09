# Define URLs
$primaryUrl = "https://zohotruesync.nimbuspop.com/ZohoWorkDriveTS.msi"
$backupUrl  = "https://files-accl.zohopublic.com/public/tswin/download/d501492ef336331284839784096b057b"

# Define destination path in temp directory
$tempDir = [System.IO.Path]::GetTempPath()
$destFile = Join-Path $tempDir "ZohoWorkDriveTS.msi"
$logFile  = Join-Path $tempDir "ZohoWorkDriveTS_install.log"

Write-Host "Attempting to download from primary URL..."

try {
    Invoke-WebRequest -Uri $primaryUrl -OutFile $destFile -ErrorAction Stop
    Write-Host "Download succeeded from primary URL."
}
catch {
    Write-Host "Primary URL failed. Attempting backup URL..."
    try {
        Invoke-WebRequest -Uri $backupUrl -OutFile $destFile -ErrorAction Stop
        Write-Host "Download succeeded from backup URL."
    }
    catch {
        Write-Host "Both download attempts failed."
        exit 1
    }
}

Write-Host "Running installer silently with logging..."
Start-Process "msiexec.exe" -ArgumentList "/i `"$destFile`" /qn /norestart /L*v `"$logFile`"" -Wait

Write-Host "Installation completed. Log file saved to: $logFile"