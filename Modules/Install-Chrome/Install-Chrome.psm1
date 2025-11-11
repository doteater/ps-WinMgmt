function Install-Chrome {
  winget install --id Google.Chrome --scope machine --accept-source-agreements --accept-package-agreements --silent --disable-interactivity
  
  set-executionpolicy unrestricted -scope process
  irm https://raw.githubusercontent.com/cory-sc/Manage-Browser-Extensions/refs/heads/main/Manage-Browser-Extensions.ps1 -o C:\windows\temp\mbe.ps1
  . C:\windows\temp\mbe.ps1
  Force-InstallExtension -Browser "Chrome" -ExtensionID "ddkjiahejlhfcafbddmgiahcphecmpfh"
  Force-InstallExtension -Browser "Edge" -ExtensionID "odfafepnkmbhccpbejgmiehpchacaeak"
}
