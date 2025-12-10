function RunAs-Admin {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Command,
        
        [Parameter(Mandatory=$true)]
        [string]$Username,
        
        [Parameter(Mandatory=$true)]
        [string]$Password,
        
        [string]$TaskName = "TempAdminTask",
        [string]$OutputFile = "C:\temp\admin_output.txt",
        [switch]$PowerShell
    )
    
    # Ensure temp directory exists
    if (!(Test-Path "C:\temp")) {
        New-Item -ItemType Directory -Path "C:\temp" -Force | Out-Null
    }
    
    # Clean up any existing output file
    if (Test-Path $OutputFile) {
        Remove-Item $OutputFile -Force
    }
    
    # Create the appropriate command file
    if ($PowerShell) {
        # For PowerShell commands, create a .ps1 file to avoid quote escaping hell
        $scriptFile = "C:\temp\admin_script.ps1"
        $Command | Out-File -FilePath $scriptFile -Encoding UTF8
        $finalCommand = "powershell.exe -ExecutionPolicy Bypass -File `"$scriptFile`""
    } else {
        # For regular commands, use batch file
        $batchFile = "C:\temp\admin_command.bat"
        $batchContent = "@echo off`r`n$Command"
        $batchContent | Out-File -FilePath $batchFile -Encoding ASCII
        $finalCommand = "`"$batchFile`""
    }
    
    # Create output redirection batch file
    $wrapperBatch = "C:\temp\admin_wrapper.bat"
    $wrapperContent = "@echo off`r`n$finalCommand > `"$OutputFile`" 2>&1"
    $wrapperContent | Out-File -FilePath $wrapperBatch -Encoding ASCII
    
    try {
        # Create the scheduled task to run the wrapper batch file
        schtasks /create /tn $TaskName /tr "`"$wrapperBatch`"" /sc once /st 00:00 /ru $Username /rp $Password /f | Out-Null
        
        # Run the task
        schtasks /run /tn $TaskName | Out-Null
        
        # Wait for completion with timeout
        $timeout = 30
        $elapsed = 0
        do {
            Start-Sleep -Seconds 1
            $elapsed++
            $status = schtasks /query /tn $TaskName /fo csv 2>$null | ConvertFrom-Csv | Select-Object -Last 1
        } while ($status.Status -eq "Running" -and $elapsed -lt $timeout)
        
        # Get the output
        Start-Sleep -Seconds 1
        if (Test-Path $OutputFile) {
            Get-Content $OutputFile
        } else {
            Write-Host "No output file created - command may have failed"
        }
        
    } finally {
        # Clean up
        schtasks /delete /tn $TaskName /f 2>$null | Out-Null
        @($scriptFile, $batchFile, $wrapperBatch) | ForEach-Object {
            if ($_ -and (Test-Path $_)) {
                Remove-Item $_ -Force
            }
        }
    }
}

function Invoke-AdminPowerShell {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Script,
        
        [Parameter(Mandatory=$true)]
        [string]$Username,
        
        [Parameter(Mandatory=$true)]
        [string]$Password
    )
    
    RunAs-Admin -Command $Script -Username $Username -Password $Password -PowerShell
}

function Set-RegistryValue {
    param (
        [string]$Hive,
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [Microsoft.Win32.RegistryValueKind]$Kind,
        [string]$User,
        [switch]$AllUsers
    )
    Process-Registry -Hive $Hive -Path $Path -Name $Name -Value $Value -Kind $Kind -User $User -AllUsers:$AllUsers -Action 'Set'
}

function Remove-RegistryValue {
    param (
        [string]$Hive,
        [string]$Path,
        [string]$Name,
        [string]$User,
        [switch]$AllUsers
    )
    Process-Registry -Hive $Hive -Path $Path -Name $Name -User $User -AllUsers:$AllUsers -Action 'RemoveValue'
}

function Remove-RegistryKey {
    param (
        [string]$Hive,
        [string]$Path,
        [string]$User,
        [switch]$AllUsers
    )
    Process-Registry -Hive $Hive -Path $Path -User $User -AllUsers:$AllUsers -Action 'RemoveKey'
}

function Process-Registry {
    param (
        [string]$Hive,
        [string]$Path,
        [string]$Name,
        [object]$Value,
        [Microsoft.Win32.RegistryValueKind]$Kind = [Microsoft.Win32.RegistryValueKind]::String,
        [string]$User,
        [switch]$AllUsers,
        [ValidateSet('Set','RemoveValue','RemoveKey')]
        [string]$Action
    )

    $systemAccounts = @('systemprofile','LocalService','NetworkService','Public','All Users','Default User')
    $profiles = @()   # <-- initialize properly

    # Collect profiles from ProfileList
    $profiles = @( 
        Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" |
            ForEach-Object {
                $props = Get-ItemProperty -Path $_.PSPath
                $profilePath = $props.ProfileImagePath
                if ($profilePath -and (Test-Path $profilePath)) {
                    $username = Split-Path $profilePath -Leaf
                    if ($systemAccounts -notcontains $username) {
                        [PSCustomObject]@{
                            SID         = $_.PSChildName
                            ProfilePath = $profilePath
                            Username    = $username
                        }
                    }
                }
            }
    )


    # Add Default User explicitly
    $defaultUserPath = "C:\Users\Default"
    if (Test-Path $defaultUserPath) {
        $profiles += [PSCustomObject]@{
            SID         = "DEFAULT"
            ProfilePath = $defaultUserPath
            Username    = "Default"
        }
    }

    if ($User) {
        $profiles = $profiles | Where-Object { $_.Username -eq $User }
        if (-not $profiles) {
            Write-Warning "User '$User' not found"
            return
        }
    }

    foreach ($profile in $profiles) {
        $sid = $profile.SID
        $targetPath = $Path -replace '^HKEY_CURRENT_USER\\|^HKCU\\', ''

        # Handle Default User separately
        if ($sid -eq "DEFAULT") {
            $ntUserPath = Join-Path $profile.ProfilePath "NTUSER.DAT"
            if (Test-Path $ntUserPath) {
                $tempHive = "TempHive_Default"
                $loadResult = & reg load "HKLM\$tempHive" $ntUserPath 2>&1
                if ($LASTEXITCODE -eq 0) {
                    try {
                        $fullPath = "Registry::HKEY_LOCAL_MACHINE\$tempHive\$targetPath"
                        Invoke-RegistryAction -FullPath $fullPath -Name $Name -Value $Value -Kind $Kind -Action $Action -UserLabel "Default User"
                    }
                    finally {
                        & reg unload "HKLM\$tempHive" | Out-Null
                    }
                }
            }
            continue
        }

        # Logged-in user hive
        if (Test-Path "Registry::HKEY_USERS\$sid") {
            $fullPath = "Registry::HKEY_USERS\$sid\$targetPath"
            Invoke-RegistryAction -FullPath $fullPath -Name $Name -Value $Value -Kind $Kind -Action $Action -UserLabel $profile.Username
        }
        else {
            # Logged-out user hive
            $ntUserPath = Join-Path $profile.ProfilePath "NTUSER.DAT"
            if (Test-Path $ntUserPath) {
                $tempHive = "TempHive_$($sid -replace '-','')"
                $loadResult = & reg load "HKLM\$tempHive" $ntUserPath 2>&1
                if ($LASTEXITCODE -eq 0) {
                    try {
                        $fullPath = "Registry::HKEY_LOCAL_MACHINE\$tempHive\$targetPath"
                        Invoke-RegistryAction -FullPath $fullPath -Name $Name -Value $Value -Kind $Kind -Action $Action -UserLabel $profile.Username
                    }
                    finally {
                        & reg unload "HKLM\$tempHive" | Out-Null
                    }
                }
            }
        }
    }
}

function Invoke-RegistryAction {
    param (
        [string]$FullPath,
        [string]$Name,
        [object]$Value,
        [Microsoft.Win32.RegistryValueKind]$Kind,
        [string]$Action,
        [string]$UserLabel
    )

    switch ($Action) {
        'Set' {
            if (-not (Test-Path $FullPath)) { New-Item -Path $FullPath -Force | Out-Null }
            Set-ItemProperty -Path $FullPath -Name $Name -Value $Value -Type $Kind
            Write-Host "Set value for $UserLabel"
        }
        'RemoveValue' {
            if (Test-Path $FullPath) {
                Remove-ItemProperty -Path $FullPath -Name $Name -ErrorAction SilentlyContinue
                Write-Host "Removed value for $UserLabel"
            }
        }
        'RemoveKey' {
            if (Test-Path $FullPath) {
                Remove-Item -Path $FullPath -Recurse -Force
                Write-Host "Removed key for $UserLabel"
            }
        }
    }
}

