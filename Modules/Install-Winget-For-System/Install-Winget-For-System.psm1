function Install-Winget-For-System {
    function Download-Winget {
        $ProgressPreference = 'SilentlyContinue'
        $7zipFolder = "${env:WinDir}\\Temp\\7zip"
        $stageFolder = "${env:WinDir}\\Temp\\WinGet-Stage"
        $bundlePath = "$stageFolder\\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"

        $wingetInstalled = Get-ItemProperty -Path C:\ProgramData\Microsoft.DesktopAppInstaller\winget.exe

        if($wingetInstalled) {
            write "SYSTEM winget already installed, defining winget() passthru function only"
            $Global:winget = "${env:ProgramData}\\Microsoft.DesktopAppInstaller\\WinGet.exe"
            Write-Host "WinGet available at $Global:winget"
            return 
        }
    
        try {
            if (Test-Path $bundlePath) {
                try { Remove-Item $bundlePath -Force } catch { Write-Host "Could not remove old bundle: $_" }
            }
            # Step 1: Get latest version from redirect URL
            $resp = Invoke-WebRequest -UseBasicParsing -Uri "https://aka.ms/getwinget" -MaximumRedirection 0 -ErrorAction SilentlyContinue
            $latestUrl = $resp.Headers.Location
            if (-not $latestUrl) {
                Write-Host "Could not determine latest WinGet version from aka.ms"
                return
            }
            # Extract version number from URL (e.g. v1.12.350 → 1.12.350.0)
            if ($latestUrl -match "v(\d+\.\d+\.\d+)") {
                $latestVersion = "$($Matches[1]).0"
            } else {
                Write-Host "Could not parse version from $latestUrl"
                return
            }
    
            Write-Host "Latest WinGet version available: $latestVersion"
    
            # Step 2: Check local bundle if it exists
            if (Test-Path $bundlePath) {
                try {
                    Add-Type -AssemblyName System.IO.Compression.FileSystem
                    $zip = [System.IO.Compression.ZipFile]::OpenRead($bundlePath)
                    $entry = $zip.Entries | Where-Object { $_.FullName -match "AppxBundleManifest.xml" }
                    $manifest = Get-AppxPackageManifest -Package $bundlePath
                    $localVersion = $manifest.Package.Identity.Version
                    Write-Host "Local WinGet bundle version: $localVersion"
    
                    if ([version]$localVersion -ge [version]$latestVersion) {
                        Write-Host "Local bundle is up to date. Skipping download."
                        $Script:WinGet = "${env:ProgramData}\\Microsoft.DesktopAppInstaller\\WinGet.exe"
                        return
                    } else {
                        Write-Host "Local bundle is outdated. Updating..."
                    }
                } catch {
                    Write-Host "Failed to read local manifest, will re-download."
                }
            }
    
            # Step 3: Download Desktop App Installer msixbundle
            Write-Host "Downloading WinGet..."
            New-Item -ItemType Directory -Path $stageFolder -Force | Out-Null
            Invoke-WebRequest -UseBasicParsing -Uri https://aka.ms/getwinget -OutFile $bundlePath
        }
        catch {
            Write-Host "Failed to download WinGet!"
            Write-Host $_.Exception.Message
            return
        }
    
        try {
            Write-Host "Downloading 7zip CLI executable..."
            New-Item -ItemType Directory -Path $7zipFolder -Force | Out-Null
            Invoke-WebRequest -UseBasicParsing -Uri https://www.7-zip.org/a/7zr.exe -OutFile "$7zipFolder\\7zr.exe"
            Invoke-WebRequest -UseBasicParsing -Uri https://www.7-zip.org/a/7z2408-extra.7z -OutFile "$7zipFolder\\7zr-extra.7z"
            Write-Host "Extracting 7zip CLI executable to ${7zipFolder}..."
            & "$7zipFolder\\7zr.exe" x "$7zipFolder\\7zr-extra.7z" -o"$7zipFolder" -y
        }
        catch {
            Write-Host "Failed to download 7zip CLI executable!"
            Write-Host $_.Exception.Message
            return
        }
    
        try {
            New-Item -ItemType Directory -Path "${env:ProgramData}\\Microsoft.DesktopAppInstaller" -Force | Out-Null
            Write-Host "Extracting WinGet..."
            & "$7zipFolder\\7za.exe" x $bundlePath -o"$stageFolder" -y 'AppInstaller_x64.msix'
            & "$7zipFolder\\7za.exe" x "$stageFolder\\AppInstaller_x64.msix" -o"${env:ProgramData}\\Microsoft.DesktopAppInstaller" -y
        }
        catch {
            Write-Host "Failed to extract WinGet!"
            Write-Host $_.Exception.Message
            return
        }
    
        if (-Not (Test-Path "${env:ProgramData}\\Microsoft.DesktopAppInstaller\\WinGet.exe")) {
            Write-Host "Failed to extract WinGet!"
            exit 1
        }
    
        $Global:winget = "${env:ProgramData}\\Microsoft.DesktopAppInstaller\\WinGet.exe"
        Write-Host "WinGet available at $Global:winget"
    }

    
    
    
function Install-VisualC {
    # Check if VC++ Redistributable is already installed
    $vcInstalled = Get-ItemProperty `
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*" ,
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" `
        -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like "Microsoft Visual C++*Redistributable*" -and $_.DisplayName -like "*2022*" }

    if ($vcInstalled) {
        Write-Output "Visual C++ Redistributable is already installed. Skipping installation."
        return 0
    }

    try {
        $downloadurl = 'https://aka.ms/vs/17/release/vc_redist.x64.exe'
        $WebClient = New-Object System.Net.WebClient
        $WebClient.DownloadFile($downloadurl, "$env:Temp\vc_redist.x64.exe")
        $WebClient.Dispose()
    }
    catch {
        Write-Output "Failed to download Visual C++!"
        Write-Output $_.Exception.Message
        return 1
    }

    # Check if another installation is in progress, then wait for it to complete
    $MSIExecCheck = Get-Process | Where-Object { $_.ProcessName -eq 'msiexec' }
    if ($Null -ne $MSIExecCheck) {
        Write-Output "Another MSI installation is in progress. Waiting for process to complete..."
        Wait-Process msiexec
        Write-Output "Continuing installation..."
    }

    try {
        $Install = Start-Process "$env:Temp\vc_redist.x64.exe" -ArgumentList "/q /norestart" -Wait -PassThru
        Write-Output "Installation completed with exit code $($Install.ExitCode)"
        return $Install.ExitCode
    }
    catch {
        Write-Output $_.Exception.Message
        return 1
    }
    finally {
        try {
            Remove-Item "$env:Temp\vc_redist.x64.exe" -ErrorAction SilentlyContinue
        }
        catch {
            Write-Output "Failed to remove vc_redist.x64.exe after installation"
        }
    }
}

    download-winget

    install-visualc

    function global:winget {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Args
    )

    # Path to winget.exe (adjust if needed)
    $wingetPath = "C:\ProgramData\Microsoft.DesktopAppInstaller\winget.exe"

    # Call winget.exe with all arguments passed through
    & $wingetPath @Args
}

}
