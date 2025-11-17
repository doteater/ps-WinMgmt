function Apply-Optimizer {

    Start-Transcript C:\windows\temp\optimizer.log
    $DebugPreference = 'Continue'
    
    
    $tempFile = [System.IO.Path]::GetTempFileName() + '.ps1'
    Invoke-WebRequest -Uri 'https://gist.githubusercontent.com/doteater/7553d248a7572caa65b67ce678c0ae34/raw/807fb6cc06939903c160ee45633213480dd34b16/gistfile1.txt' -OutFile $tempFile
    
    # Self-Elevation Function
    Function Elevate-Script {
        If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            $newProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell"
            $newProcess.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$tempFile`""
            $newProcess.Verb = "runas"
            [System.Diagnostics.Process]::Start($newProcess) | Out-Null
            Exit
        }
    }
    
    # Invoke Self-Elevation
    Elevate-Script
    
    
    # Define paths
    $tempDir = $env:TEMP
    $jsonPath = Join-Path $tempDir "c.json"
    $exePath  = Join-Path $tempDir "o.exe"
    
    # JSON content
    $jsonContent = \
@'
    {
        "WindowsVersion": 11,
        "PostAction": {
            "Restart": true,
            "RestartType": "Normal"
        },
        "Cleaner": {
            "TempFiles": null,
            "BsodDumps": null,
            "ErrorReports": null,
            "RecycleBin": null,
            "InternetExplorer": null,
            "GoogleChrome": {
                "Cache": null,
                "Cookies": null,
                "History": null,
                "Session": null,
                "Passwords": null
            },
            "MozillaFirefox": {
                "Cache": null,
                "Cookies": null,
                "History": null
            },
            "MicrosoftEdge": {
                "Cache": null,
                "Cookies": null,
                "History": null,
                "Session": null
            },
            "BraveBrowser": {
                "Cache": null,
                "Cookies": null,
                "History": null,
                "Session": null,
                "Passwords": null
            }
        },
        "Pinger": {
            "SetDNS": "",
            "CustomDNSv4": [],
            "CustomDNSv6": [],
            "FlushDNSCache": null
        },
        "ProcessControl": {
            "Prevent": [],
            "Allow": []
        },
        "HostsEditor": {
            "Block": [],
            "Add": [],
            "Remove": [],
            "IncludeWwwCname": null
        },
        "RegistryFix": {
            "TaskManager": null,
            "CommandPrompt": null,
            "ControlPanel": null,
            "FolderOptions": null,
            "RunDialog": null,
            "RightClickMenu": null,
            "WindowsFirewall": null,
            "RegistryEditor": null
        },
        "Integrator": {
            "TakeOwnership": null,
            "OpenWithCMD": null
        },
        "AdvancedTweaks": {
            "UnlockAllCores": null,
            "DisableHPET": null,
            "EnableRegistryBackups": null,
            "EnableLoginVerbose": null,
            "SvchostProcessSplitting": {
                "Disable": null,
                "RAM": null
            }
        },
        "Tweaks": {
            "EnablePerformanceTweaks": true,
            "DisableNetworkThrottling": true,
            "DisableWindowsDefender": null,
            "DisableSystemRestore": null,
            "DisablePrintService": null,
            "DisableMediaPlayerSharing": true,
            "DisableErrorReporting": true,
            "DisableHomeGroup": true,
            "DisableSuperfetch": null,
            "DisableTelemetryTasks": true,
            "DisableOffice2016Telemetry": true,
            "DisableCompatibilityAssistant": true,
            "DisableHibernation": null,
            "DisableSMB1": true,
            "DisableSMB2": true,
            "DisableNTFSTimeStamp": null,
            "DisableFaxService": true,
            "DisableSmartScreen": null,
            "DisableStickyKeys": true,
            "DisableCloudClipboard": true,
            "EnableLegacyVolumeSlider": null,
            "DisableQuickAccessHistory": null,
            "DisableStartMenuAds": true,
            "UninstallOneDrive": true,
            "DisableMyPeople": true,
            "DisableAutomaticUpdates": null,
            "ExcludeDrivers": null,
            "DisableTelemetryServices": true,
            "DisablePrivacyOptions": null,
            "DisableCortana": true,
            "DisableSensorServices": null,
            "DisableWindowsInk": true,
            "DisableSpellingTyping": true,
            "DisableXboxLive": true,
            "DisableGameBar": true,
            "DisableInsiderService": true,
            "DisableStoreUpdates": null,
            "EnableLongPaths": true,
            "RemoveCastToDevice": null,
            "EnableGamingMode": null,
            "TaskbarToLeft": null,
            "DisableSnapAssist": null,
            "DisableWidgets": true,
            "DisableChat": true,
            "TaskbarSmaller": null,
            "DisableStickers": true,
            "ClassicRibbon": null,
            "ClassicMenu": null,
            "DisableTPMCheck": null,
            "CompactMode": null,
            "DisableVirtualizationBasedTechnology": null,
            "DisableVisualStudioTelemetry": true,
            "DisableFirefoxTemeletry": true,
            "DisableChromeTelemetry": true,
            "DisableNVIDIATelemetry": true,
            "DisableSearch": null,
            "DisableEdgeDiscoverBar": true,
            "DisableEdgeTelemetry": true,
            "DisableCoPilotAI": true,
            "RestoreClassicPhotoViewer": true,
            "EnableUtcTime": null,
            "ShowAllTrayIcons": null,
            "RemoveMenusDelay": true,
            "DisableModernStandby": null,
            "HideTaskbarWeather": true,
            "HideTaskbarSearch": true,
            "DisableNewsInterests": true
        }
    }
'@
    
    # Write JSON to file (force overwrite)
    $jsonContent | Set-Content -Path $jsonPath -Force -Encoding UTF8
    
    # Download executable
    remove-item -force -ErrorAction SilentlyContinue $exePath
    #$downloadUrl = "https://github.com/hellzerg/optimizer/releases/download/16.7/Optimizer-16.7.exe"
    $downloadUrl = "https://github.com/doteater/ps-WinMgmt/raw/refs/heads/main/Optimizer-16.7.exe"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $exePath 
    
    # Run executable with config
    & $exePath "/config:$jsonPath"
}
