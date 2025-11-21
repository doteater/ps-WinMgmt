function Apply-Policies {
  #prevent connecting to MS account
  Set-RegistryValue "HKEY_LOCAL_MACHINE" "Software\Policies\Microsoft\MicrosoftAccount" "DisableUserAuth" 1 DWord
  Set-RegistryValue "HKEY_LOCAL_MACHINE" "SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" "NoConnectedUser" 3 DWord
  Set-RegistryValue "HKEY_LOCAL_MACHINE" "SOFTWARE\Microsoft\PolicyManager\default\Settings\AllowYourAccount" "value" 0 DWord
  
  #prevent enabling bitlocker
  Set-RegistryValue "HKEY_LOCAL_MACHINE" "SYSTEM\CurrentControlSet\Control\BitLocker" "PreventDeviceEncryption" 1 DWord
  
  ##update time zone automatically
  Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location' -Name 'Value' -Value 'Allow' -Type String
  # Ensure per-machine policy isn't blocking location (if present)
  Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' -Name 'DisableLocation' -ErrorAction SilentlyContinue
  Set-RegistryValue "HKEY_LOCAL_MACHINE" "SYSTEM\CurrentControlSet\Services\tzautoupdate" "Start" 3 DWord
  #restart service to take effect
  Start-Service -Name tzautoupdate -ErrorAction SilentlyContinue

  
  #disable MS Office MS Account sign-in button
  Set-RegistryValue "HKEY_CURRENT_USER" "SOFTWARE\Microsoft\Office\16.0\Common\SignIn" "SignInOptions" 3 DWord
  Set-RegistryValue "HKEY_CURRENT_USER" "SOFTWARE\Microsoft\Office\16.0\Common\SignIn" "SignInOptions" 3 DWord -AllUsers -IncludeDefault
  
  
  #add ublock on chrome and edge
  set-executionpolicy unrestricted -scope process
  irm https://raw.githubusercontent.com/cory-sc/Manage-Browser-Extensions/refs/heads/main/Manage-Browser-Extensions.ps1 -o C:\windows\temp\mbe.ps1
  . C:\windows\temp\mbe.ps1
  Force-InstallExtension -Browser "Chrome" -ExtensionID "ddkjiahejlhfcafbddmgiahcphecmpfh"
  Force-InstallExtension -Browser "Edge" -ExtensionID "odfafepnkmbhccpbejgmiehpchacaeak"
}
