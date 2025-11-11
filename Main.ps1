param(
    [switch]$RunAll,
    [switch]$NoSleepMode,
    [switch]$OtherModule
)

Write-Host "=== ps-WinMgmt Master Script ==="

# Import modules (adjust paths if needed)
Import-Module NoSleepMode -ErrorAction SilentlyContinue
Import-Module OtherModule -ErrorAction SilentlyContinue

if ($RunAll -or (-not $NoSleepMode -and -not $OtherModule)) {
    Write-Host "Running all modules..."
    Set-NoSleepMode -Enable $true
    Invoke-OtherModule
}
else {
    if ($NoSleepMode) {
        Write-Host "Running NoSleepMode..."
        Set-NoSleepMode -Enable $true
    }
    if ($OtherModule) {
        Write-Host "Running OtherModule..."
        Invoke-OtherModule
    }
}

Write-Host "=== ps-WinMgmt Master Script Complete ==="
