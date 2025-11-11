Write-Host "=== ps-WinMgmt Main Script ==="

# Get all subfolders under the WinMgmt module directory
$moduleRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$subModules = Get-ChildItem -Path $moduleRoot -Directory

foreach ($mod in $subModules) {
    $modName = $mod.Name
    $psm1 = Join-Path $mod.FullName "$modName.psm1"

    if (Test-Path $psm1) {
        try {
            Write-Host "Importing module: $modName"
            Import-Module $psm1 -Force -ErrorAction Stop

            # Try to run a default entry point if it exists
            $defaultFunc = "Invoke-$modName"
            if (Get-Command $defaultFunc -ErrorAction SilentlyContinue) {
                Write-Host "Running $defaultFunc..."
                & $defaultFunc
            }
            elseif (Get-Command "Set-$modName" -ErrorAction SilentlyContinue) {
                Write-Host "Running Set-$modName..."
                & ("Set-$modName") -Enable $true
            }
            else {
                Write-Host "No default function found for $modName, imported only."
            }
        }
        catch {
            Write-Warning "Failed to import or run $modName: $_"
        }
    }
}

Write-Host "=== ps-WinMgmt Main Script Complete ==="
