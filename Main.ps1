Write-Host "=== ps-WinMgmt Main Script ==="

# Path to the Modules folder inside WinMgmt
$moduleRoot = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) "Modules"
$subModules = Get-ChildItem -Path $moduleRoot -Directory

write "found sub-modules: $submodules"

foreach ($mod in $subModules) {
    write "processing submodule $mod"
    $modName = $mod.Name
    $psm1 = Join-Path $mod.FullName "$modName.psm1"

    if (Test-Path $psm1) {
        try {
            Write-Host "Importing module: $modName"
            Import-Module $psm1 -Force -ErrorAction Stop

            # Run default entry point if defined
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
            Write-Warning "Failed to import or run $modName -  $($_.Exception.Message)"
        }
    }
}

Write-Host "=== ps-WinMgmt Main Script Complete ==="
