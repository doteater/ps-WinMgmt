function Update-LenovoTVSU {

    Set-ExecutionPolicy Unrestricted
    if (-not (Get-PSRepository -Name 'PSGallery' -ErrorAction SilentlyContinue)) {
        Register-PSRepository -Default
    }
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
    Install-PackageProvider -Name NuGet -Force

    Install-Module -Name 'LSUClient'
    $updates = Get-LSUpdate | Where-Object { $_.Installer.Unattended }
    $updates | Save-LSUpdate -Verbose
    $updates | Install-LSUpdate -Verbose
}