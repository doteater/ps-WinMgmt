
function Update-PerformanceSettings {
Write-Host "Setting Windows to Best Performance for ALL users..." -ForegroundColor Cyan

# Function to apply settings to a registry hive
function Set-PerformanceSettings {
    param($HivePath)
    
    # Set visual effects to best performance
    $path = "$HivePath\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
    if (!(Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-ItemProperty -Path $path -Name VisualFXSetting -Value 2
    
    # Disable individual visual effects
    $advPath = "$HivePath\Control Panel\Desktop"
    Set-ItemProperty -Path $advPath -Name UserPreferencesMask -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -Type Binary
    Set-ItemProperty -Path $advPath -Name MinAnimate -Value 0
    Set-ItemProperty -Path $advPath -Name WindowArrangementActive -Value 0
    Set-ItemProperty -Path $advPath -Name SmoothScroll -Value 0
    
    # Disable menu animations
    $wmPath = "$HivePath\Control Panel\Desktop\WindowMetrics"
    if (!(Test-Path $wmPath)) { New-Item -Path $wmPath -Force | Out-Null }
    Set-ItemProperty -Path $wmPath -Name MinAnimate -Value 0
    
    # Disable taskbar animations
    $advancedPath = "$HivePath\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    if (!(Test-Path $advancedPath)) { New-Item -Path $advancedPath -Force | Out-Null }
    Set-ItemProperty -Path $advancedPath -Name TaskbarAnimations -Value 0
    Set-ItemProperty -Path $advancedPath -Name ListviewAlphaSelect -Value 0
    Set-ItemProperty -Path $advancedPath -Name ListviewShadow -Value 0
    
    # Disable peek preview
    $dwmPath = "$HivePath\Software\Microsoft\Windows\DWM"
    if (!(Test-Path $dwmPath)) { New-Item -Path $dwmPath -Force | Out-Null }
    Set-ItemProperty -Path $dwmPath -Name EnableAeroPeek -Value 0
    
    # Disable transparency effects
    $themePath = "$HivePath\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    if (!(Test-Path $themePath)) { New-Item -Path $themePath -Force | Out-Null }
    Set-ItemProperty -Path $themePath -Name EnableTransparency -Value 0
}

# Apply to current user
Write-Host "Applying settings to current user..." -ForegroundColor Yellow
Set-PerformanceSettings -HivePath "HKCU:"

# Apply to default user profile (for new users)
Write-Host "Applying settings to default user profile..." -ForegroundColor Yellow
$defaultHive = "HKLM:\DefaultUser"
reg load "HKLM\DefaultUser" "C:\Users\Default\NTUSER.DAT" 2>$null
if (Test-Path $defaultHive) {
    Set-PerformanceSettings -HivePath $defaultHive
    [gc]::Collect()
    Start-Sleep -Seconds 2
    reg unload "HKLM\DefaultUser" 2>$null
}

# Apply to all existing user profiles
Write-Host "Applying settings to all existing users..." -ForegroundColor Yellow
$userProfiles = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | 
    Where-Object { $_.GetValue("ProfileImagePath") -like "C:\Users\*" }

foreach ($profile in $userProfiles) {
    $sid = $profile.PSChildName
    $username = Split-Path $profile.GetValue("ProfileImagePath") -Leaf
    
    # Skip system accounts
    if ($username -notmatch '^(Public|Default|All Users|Default User)$') {
        Write-Host "  Processing: $username" -ForegroundColor Gray
        
        # Check if user hive is already loaded
        if (Test-Path "Registry::HKEY_USERS\$sid") {
            Set-PerformanceSettings -HivePath "Registry::HKEY_USERS\$sid"
        }
        else {
            # Load user hive temporarily
            $userHivePath = $profile.GetValue("ProfileImagePath") + "\NTUSER.DAT"
            if (Test-Path $userHivePath) {
                $tempKey = "HKLM\TempUserHive_$sid"
                reg load $tempKey $userHivePath 2>$null
                if (Test-Path "HKLM:\TempUserHive_$sid") {
                    Set-PerformanceSettings -HivePath "HKLM:\TempUserHive_$sid"
                    [gc]::Collect()
                    Start-Sleep -Seconds 1
                    reg unload $tempKey 2>$null
                }
            }
        }
    }
}

Write-Host "`nRestarting Explorer..." -ForegroundColor Green
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

Write-Host "`nDone! Performance settings applied to all users." -ForegroundColor Green
Write-Host "Current users may need to log out and back in for all changes to take effect." -ForegroundColor Yellow
Write-Host "New users will automatically get these settings." -ForegroundColor Yellow
}
