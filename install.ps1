param(
    [string]$RepoUrl = "https://github.com/doteater/ps-WinMgmt/archive/refs/heads/main.zip",
    [string]$ModuleName = "WinMgmt",
    [ValidateSet("User","AllUsers")]
    [string]$Scope = "AllUsers"
)

# Decide destination based on scope (Windows PowerShell only)
if ($Scope -eq "User") {
    $basePath = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Modules"
} else {
    $basePath = "C:\Program Files\WindowsPowerShell\Modules"
}

$dest     = Join-Path $basePath $ModuleName
$tempZip  = Join-Path $env:TEMP "$ModuleName.zip"
$tempDir  = Join-Path $env:TEMP "$ModuleName"

#
Remove-Module nosleepmode
remove-module winmgmt

# Clean up any previous temp files
if (Test-Path $tempZip) { Remove-Item $tempZip -Force }
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }

# Download fresh repo zip
Invoke-WebRequest -Uri $RepoUrl -OutFile $tempZip -UseBasicParsing

# Extract to temp
Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force

# Remove old installed copy
if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }

# Copy new module into place
$sourceDir = Get-ChildItem $tempDir -Directory | Select-Object -First 1
Copy-Item -Path $sourceDir.FullName -Destination $dest -Recurse -Force

Write-Host "Module installed to $dest"

# Clean up temp files
Remove-Item $tempZip -Force
Remove-Item $tempDir -Recurse -Force

# Call the Main script inside ps-WinMgmt
$mainScript = Join-Path $dest "Main.ps1"
if (Test-Path $mainScript) {
    Write-Host "Running main script: $mainScript"
    Set-ExecutionPolicy Unrestricted -Scope Process
    & $mainScript
} else {
    Write-Warning "Main.ps1 not found in $dest"
}
