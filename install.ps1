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
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }

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