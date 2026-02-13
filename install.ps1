set-executionpolicy unrestricted -scope process

param(
    [string]$RepoUrl = "https://github.com/doteater/ps-WinMgmt/archive/refs/heads/main.zip",
    [string]$ModuleName = "WinMgmt",
    [ValidateSet("User","AllUsers")]
    [string]$Scope = "AllUsers"
)


$stagingDir = "$Env:temp\ps-WinMgmt-staging"

$allUsersModuleRoot = Join-Path $env:ProgramFiles 'WindowsPowerShell\Modules'  # Windows PowerShell
if (-not (Test-Path $allUsersModuleRoot)) {
    $allUsersModuleRoot = Join-Path $env:ProgramFiles 'PowerShell\Modules'     # PowerShell 7+
}


# Clean up any previous stuff
if (Test-Path $stagingDir) { Remove-Item $stagingDir -Recurse -Force }

# Download fresh repo zip
New-Item -ItemType Directory $stagingDir
Invoke-RestMethod -Uri $RepoUrl -OutFile $stagingDir\repo.zip
Expand-Archive -Path $stagingDir\repo.zip -DestinationPath $stagingDir -Force

#cd $stagingDir

$sourceRoot = Join-Path $stagingDir\ps-WinMgmt-main 'Modules'

$allUsersModuleRoot = Join-Path $env:ProgramFiles 'WindowsPowerShell\Modules'  # Windows PowerShell
if (-not (Test-Path $allUsersModuleRoot)) {
    $allUsersModuleRoot = Join-Path $env:ProgramFiles 'PowerShell\Modules'     # PowerShell 7+
}

Write-Host "Installing modules from: $sourceRoot"
Write-Host "Target module path:      $allUsersModuleRoot"

Get-ChildItem -Path $sourceRoot -Directory | ForEach-Object {
    $moduleFolder = $_
    $moduleName   = $moduleFolder.Name
    $psm1Path     = Join-Path $moduleFolder.FullName "$moduleName.psm1"

    if (-not (Test-Path $psm1Path)) {
        Write-Warning "Skipping '$moduleName' – file '$moduleName.psm1' not found in folder."
        return
    }

    $targetPath = Join-Path $allUsersModuleRoot $moduleName

    if (-not (Test-Path $targetPath)) {
        New-Item -ItemType Directory -Path $targetPath -Force | Out-Null
    }

    Copy-Item -Path $psm1Path -Destination (Join-Path $targetPath "$moduleName.psm1") -Force
    Write-Host "Installed module: $moduleName"
}

Write-Host ""
Write-Host "Modules now available (by folder name) in all-users path:"
Get-ChildItem -Path $allUsersModuleRoot -Directory | Select-Object -ExpandProperty name

#----





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
