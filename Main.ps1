param(
    [switch]$RunAll,
    [switch]$NoSleepMode,
    [switch]$Update-Locale,
    [switch]$OtherModule
)

Write-Host "=== ps-WinMgmt Main Script ==="

#Import-Module NoSleepMode -ErrorAction SilentlyContinue
Import-Module Update-Locale -ErrorAction SilentlyContinue
#Import-Module OtherModule -ErrorAction SilentlyContinue

# Default behavior: run everything if no switches are provided
if ($RunAll -or (-not $NoSleepMode -and -not $OtherModule)) {
    Write-Host "Running all modules..."
    #Set-NoSleepMode -Enable $true
    Update-Locale
    #Invoke-OtherModule
}
else {
    if ($NoSleepMode) {
        Write-Host "Running NoSleepMode..."
        Set-NoSleepMode -Enable $true
    }
    if ($Update-Locale) {
        Write-Host "Running Update-Locale..."
        Update-Locale
    }
    #if ($OtherModule) {
    #    Write-Host "Running OtherModule..."
    #    Invoke-OtherModule
    #}
}

Write-Host "=== ps-WinMgmt Main Script Complete ==="
