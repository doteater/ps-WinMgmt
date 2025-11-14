function Remove-Junk {
  $appsToRemove = @(
      "*Copilot*"
      "*DolbyLaboratories.DolbyAudioPremium*"
      "*DolbyLaboratories.DolbyDigitalPlusDecoderOEM*"
      "*DolbyLaboratories.DolbyAccess*"
      "*Microsoft.WindowsFeedbackHub*"
      "*Microsoft.Edge.GameAssist*"
      "*Ink.Handwriting*"
      "*zune*"
      "*microsoftofficehub*"
      "*bingsearch*"
      "*bingweather*"
      "*bingnews*"
      "*clipchamp*"
      "*msteams*"
      "*microsoft.todos*"
      "*outlookforwindows*"
      "*powerautomate*"
      #"*Microsoft.XboxGameCallableUI*"
      "*Microsoft.XboxIdentityProvider*"
      "*Microsoft.XboxSpeechToTextOverlay*"
      "*Microsoft.XboxGamingOverlay*"
      "*Microsoft.Xbox.TCUI*"
      "*QuickAssist*"
      "*StartExperiencesApp*"
      "*Microsoft.MicrosoftSolitaireCollection*"
      "*Microsoft.yourphone*"
      "*Microsoft.gamingapp*"
      "*aimgr*"
      "*AdvancedMicroDevicesInc-2.AMDRadeonSoftware*"
      "*Microsoft.StartExperiencesApp*"
      "*Microsoft.OneDrive*"
      "*microsoft.windowscommunicationsapps*"
      "*microsoft.windowsmaps*"
      "*microsoft.people*"
      "Microsoft.549981C3F5F10" #cortana
      "Microsoft.Microsoft3DViewer"
      "Microsoft.Wallet"
      "MicrosoftTeams"
      "Microsoft.Office.OneNote"
      "Microsoft.SkypeApp"
      "Microsoft.XboxApp"
      "Microsoft.XboxGameOverlay"
      "Microsoft.MSPaint"
      "MicrosoftWindows.Client.WebExperience"

  )
  
  # Remove apps for all existing users
  Write-Host "Removing apps for all existing users..." -ForegroundColor Cyan
  foreach ($app in $appsToRemove) {
      Write-Host "Processing: $app" -ForegroundColor Yellow
      Get-AppxPackage -AllUsers $app | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
  }
  
  # Remove provisioned packages (prevents installation for new users)
  Write-Host "`nRemoving provisioned packages..." -ForegroundColor Cyan
  foreach ($app in $appsToRemove) {
      $appName = $app.Trim("*")
      Write-Host "Processing: $app" -ForegroundColor Yellow
      Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
  }
  
  Write-Host "`nRemoval complete!" -ForegroundColor Green
  
  ### END ###
  
  
  ###
  ###"Prevent the usage of OneDrive for file storage" GPO
  # Create the policy key if it doesn't exist
  New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" -Force | Out-Null
  
  # Set the DisableFileSyncNGSC flag to 1 (prevent OneDrive usage)
  Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive" `
      -Name "DisableFileSyncNGSC" -Value 1 -Type DWord
  
  ##
  ####
  
  ### DESTROY ALL ONEDRIVES
  EXCEPT FOR THE CTR O365 one I gues...
  
  # Silent uninstall flags for OneDriveSetup.exe
  $silentArgs = "/uninstall /allusers"
  
  Write-Host "Stopping OneDrive processes..." -ForegroundColor Cyan
  Get-Process -Name OneDrive, OneDriveSetup -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 2
  
  # Get all user profiles
  $users = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | 
      ForEach-Object {
          $profilePath = (Get-ItemProperty $_.PSPath).ProfileImagePath
          if ($profilePath -and (Test-Path $profilePath) -and $profilePath -notlike "*systemprofile*") {
              [PSCustomObject]@{
                  Username = Split-Path $profilePath -Leaf
                  ProfilePath = $profilePath
              }
          }
      }
  
  # Process each user's OneDrive installation
  foreach ($user in $users) {
      Write-Host "`nProcessing user: $($user.Username)" -ForegroundColor Yellow
      
      # Look for versioned OneDriveSetup.exe in user profile
      $oneDriveBaseDir = Join-Path $user.ProfilePath "AppData\Local\Microsoft\OneDrive"
      
      if (Test-Path $oneDriveBaseDir) {
          # Search for all OneDriveSetup.exe in version directories
          $setupFiles = Get-ChildItem -Path $oneDriveBaseDir -Filter "OneDriveSetup.exe" -Recurse -ErrorAction SilentlyContinue
          
          foreach ($setup in $setupFiles) {
              Write-Host "  Found: $($setup.FullName)" -ForegroundColor Green
              Write-Host "  Running silent uninstall..." -ForegroundColor Cyan
              
              try {
                  Start-Process -FilePath $setup.FullName -ArgumentList $silentArgs -Wait -NoNewWindow -ErrorAction Stop
                  Write-Host "  Uninstall completed" -ForegroundColor Green
              } catch {
                  Write-Host "  Error: $_" -ForegroundColor Red
              }
          }
      }
  }
  
  # Process system-wide installations
  Write-Host "`nProcessing system-wide installations..." -ForegroundColor Yellow
  
  $systemLocations = @(
      "$env:SystemRoot\System32\OneDriveSetup.exe"
      "$env:SystemRoot\SysWOW64\OneDriveSetup.exe"
      "$env:ProgramFiles\Microsoft OneDrive\OneDriveSetup.exe"
      "${env:ProgramFiles(x86)}\Microsoft OneDrive\OneDriveSetup.exe"
  )
  
  foreach ($location in $systemLocations) {
      if (Test-Path $location) {
          Write-Host "  Found: $location" -ForegroundColor Green
          Write-Host "  Running silent uninstall..." -ForegroundColor Cyan
          
          try {
              Start-Process -FilePath $location -ArgumentList $silentArgs -Wait -NoNewWindow -ErrorAction Stop
              Write-Host "  Uninstall completed" -ForegroundColor Green
          } catch {
              Write-Host "  Error: $_" -ForegroundColor Red
          }
      }
  }
  
  # Clean up residual files and registry entries
  Write-Host "`nCleaning up residual files..." -ForegroundColor Yellow
  
  foreach ($user in $users) {
      $oneDriveDir = Join-Path $user.ProfilePath "AppData\Local\Microsoft\OneDrive"
      if (Test-Path $oneDriveDir) {
          Write-Host "  Removing: $oneDriveDir" -ForegroundColor Cyan
          Remove-Item -Path $oneDriveDir -Recurse -Force -ErrorAction SilentlyContinue
      }
  }
  
  # Remove OneDrive from Explorer sidebar (registry cleanup)
  Write-Host "`nRemoving OneDrive from Explorer..." -ForegroundColor Yellow
  $regPaths = @(
      "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
      "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
  )
  
  foreach ($regPath in $regPaths) {
      if (Test-Path "Registry::$regPath") {
          Remove-Item -Path "Registry::$regPath" -Recurse -Force -ErrorAction SilentlyContinue
          Write-Host "  Removed: $regPath" -ForegroundColor Green
      }
  }
  
  winget uninstall microsoft.onedrive  --all  --scope user --silent --force  --accept-source-agreements   --disable-interactivity 
  winget uninstall microsoft.onedrive  --all  --scope machine --silent --force  --accept-source-agreements   --disable-interactivity 
  
  Write-Host "`nOneDrive removal complete!" -ForegroundColor Green
}


Get-WmiObject -Class Win32_Product | Where-Object { $_.Name -like "Microsoft Update Health Tools*" } | ForEach-Object { $_.Uninstall() }

