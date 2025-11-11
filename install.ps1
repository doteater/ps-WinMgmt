param(
    [string]$RepoUrl = "https://github.com/doteater/ps-WinMgmt/archive/refs/heads/main.zip",
    [string]$ModuleName = "WinMgmt",
    [ValidateSet("User","AllUsers")]
    [string]$Scope = "AllUsers"
)

# Decide destination based on scope
if ($Scope -eq "User") {
    $basePath = Join-Path $env:USERPROFILE "Documents\WindowsPowerShell\Modules"
} else {
    $basePath = "C:\Program Files\WindowsPowerShell\Modules"
}

$dest = Join-Path $basePath $ModuleName

# Download the repo zip
$tempZip = Join-Path $env:TEMP "$ModuleName.zip"
Invoke-WebRequest -Uri $RepoUrl -OutFile $tempZip -UseBasicParsing

# Extract
$tempDir = Join-Path $env:TEMP "$ModuleName"
Expand-Archive -Path $tempZip -DestinationPath $tempDir -Force

# Copy module folder into PowerShell Modules path
$sourceDir = Get-ChildItem $tempDir -Directory | Select-Object -First 1
Copy-Item -Path $sourceDir.FullName -Destination $dest -Recurse -Force

Write-Host "Module installed to $dest"

# Call the Main script inside ps-WinMgmt
$mainScript = Join-Path $dest "Main.ps1"
if (Test-Path $mainScript) {
    Write-Host "Running main script: $mainScript"
    set-executionpolicy unrestricted -scope process
    & $mainScript
} else {
    Write-Warning "Main.ps1 not found in $dest"
}
