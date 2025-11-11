function Install-Chrome {
  function Download-Winget {
  	<#
  	.SYNOPSIS
  	Download Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle and extract contents with 7zip cli to %ProgramData%
  	#>
  	$ProgressPreference = 'SilentlyContinue'
  	$7zipFolder = "${env:WinDir}\\Temp\\7zip"
  	try {
  		write "Downloading WinGet..."
  		# Create staging folder
  		New-Item -ItemType Directory -Path "${env:WinDir}\\Temp\\WinGet-Stage" -Force
  		# Download Desktop App Installer msixbundle
  		Invoke-WebRequest -UseBasicParsing -Uri https://aka.ms/getwinget -OutFile "${env:WinDir}\\Temp\\WinGet-Stage\\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
  	}
  	catch {
  		write "Failed to download WinGet!"
  		write $_.Exception.Message
  		return
  	}
  	try {
  		write "Downloading 7zip CLI executable..."
  		# Create temp 7zip CLI folder
  		New-Item -ItemType Directory -Path $7zipFolder -Force
  		Invoke-WebRequest -UseBasicParsing -Uri https://www.7-zip.org/a/7zr.exe -OutFile "$7zipFolder\\7zr.exe"
  		Invoke-WebRequest -UseBasicParsing -Uri https://www.7-zip.org/a/7z2408-extra.7z -OutFile "$7zipFolder\\7zr-extra.7z"
  		write "Extracting 7zip CLI executable to ${7zipFolder}..."
  		& "$7zipFolder\\7zr.exe" x "$7zipFolder\\7zr-extra.7z" -o"$7zipFolder" -y
  	}
  	catch {
  		write "Failed to download 7zip CLI executable!"
  		write $_.Exception.Message
  		return
  	}
  	try {
  	# Create Folder for DesktopAppInstaller inside %ProgramData%
  	New-Item -ItemType Directory -Path "${env:ProgramData}\\Microsoft.DesktopAppInstaller" -Force
  	write "Extracting WinGet..."
  	& "$7zipFolder\\7za.exe" x "${env:WinDir}\\Temp\\WinGet-Stage\\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle" -o"${env:WinDir}\\Temp\\WinGet-Stage" -y
  	& "$7zipFolder\\7za.exe" x "${env:WinDir}\\Temp\\WinGet-Stage\\AppInstaller_x64.msix" -o"${env:ProgramData}\\Microsoft.DesktopAppInstaller" -y
  	}
  	catch {
  		write "Failed to extract WinGet!"
  		write $_.Exception.Message
  		return
  	}
  	if (-Not (Test-Path "${env:ProgramData}\\Microsoft.DesktopAppInstaller\\WinGet.exe")){
  		write "Failed to extract WinGet!"
  		exit 1
  	}
  	$Script:WinGet = "${env:ProgramData}\\Microsoft.DesktopAppInstaller\\WinGet.exe"
  }
  
  
  
  function Install-VisualC {
  	try {
  		$downloadurl = 'https://aka.ms/vs/17/release/vc_redist.x64.exe'
  		$WebClient = New-Object System.Net.WebClient
  		$WebClient.DownloadFile($downloadurl, "$env:Temp\vc_redist.x64.exe")
  		$WebClient.Dispose()
  	}
  	catch {
  		write "Failed to download Visual C++!"
  		write $_.Exception.Message
  	}
  	# Check if another installation is in progress, then wait for it to complete
  	$MSIExecCheck = Get-Process | Where-Object {$_.processname -eq 'msiexec'}
  	if ($Null -ne $MSIExecCheck){
  		write "another msi installation is in progress. Waiting for process to complete..."
  		Wait-Process msiexec
  		write "Continuing installation..."
  	}
  	try {
  		$Install = start-process "$env:temp\vc_redist.x64.exe" -argumentlist "/q /norestart" -Wait -PassThru
  		write "Installation completed with exit code $($Install.ExitCode)"
  		return $Install.ExitCode
  	}
  	catch {
  		write $_.Exception.Message
  	}
  	try {
  		remove-item "$env:Temp\vc_redist.x64.exe"
  	}
  	catch {
  		write "Failed to remove vc_redist.x64.exe after installation"
  	}
  }

  download-winget

  install-visualc

  winget install --id Google.Chrome --scope machine --accept-source-agreements --accept-package-agreements --silent --disable-interactivity
  
  set-executionpolicy unrestricted -scope process
  irm https://raw.githubusercontent.com/cory-sc/Manage-Browser-Extensions/refs/heads/main/Manage-Browser-Extensions.ps1 -o C:\windows\temp\mbe.ps1
  . C:\windows\temp\mbe.ps1
  Force-InstallExtension -Browser "Chrome" -ExtensionID "ddkjiahejlhfcafbddmgiahcphecmpfh"
  Force-InstallExtension -Browser "Edge" -ExtensionID "odfafepnkmbhccpbejgmiehpchacaeak"
}
