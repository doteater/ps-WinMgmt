function Install-WinUpdate {
  Install-PackageProvider -name nuget -force
  
  $moduleName = 'PSWindowsUpdate'
  if (-not (Get-Module -ListAvailable -Name $moduleName)) {
  Install-Module $moduleName -Force -SkipPublisherCheck
  }
  
  #----
  Set-ExecutionPolicy Unrestricted -Scope Process
  
  Import-Module PSWindowsUpdate
  
  #bring WU up to date
  Install-WindowsUpdate -AcceptAll -Download -IgnoreReboot -Install
}
