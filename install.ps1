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

# Clean up any previous temp files
if (Test-Path $tempZip) { Remove-Item $tempZip -Force }
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }

# Download fresh repo zip
Invoke-WebRequest -Uri $RepoUrl -OutFile $tempZip -UseBasicParsing
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

# --- Create a master manifest for WinMgmt ---
$manifestPath = Join-Path $dest "$ModuleName.psd1"
New-ModuleManifest -Path $manifestPath `
    -RootModule "$ModuleName.psm1" `
    -ModuleVersion "1.0.0" `
    -Author "YourName" `
    -Description "Master module that loads all submodules" `
    -NestedModules @(
        "Modules\Install-Winget-For-System\Install-Winget-For-System.psm1",
        "Modules\Remove-Junk\Remove-Junk.psm1"
    )

Write-Host "Created master manifest: $manifestPath"
