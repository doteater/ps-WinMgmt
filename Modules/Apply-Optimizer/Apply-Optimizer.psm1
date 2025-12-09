function Apply-Optimizer {

    Start-Transcript -path C:\windows\temp\optimizer.log
    $DebugPreference = 'Continue'


    # Self-Elevation Function
    Function Elevate-Script {
        If (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
            $tempFile = [System.IO.Path]::GetTempFileName() + '.ps1'
            Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/doteater/ps-WinMgmt/refs/heads/main/Modules/Apply-Optimizer/Apply-Optimizer.psm1' -OutFile $tempFile
            $newProcess = New-Object System.Diagnostics.ProcessStartInfo "PowerShell"
            $newProcess.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$tempFile`""
            $newProcess.Verb = "runas"
            [System.Diagnostics.Process]::Start($newProcess) | Out-Null
            Exit
        }
    }

    Elevate-Script

    # Detect Windows version (Major=10, Build=22000 and above = Win11, below 22000 = Win10)
    $winVer = (Get-ComputerInfo -Property OsName,OsVersion)
    $windowsVersionNumber = ($winVer.OsVersion -split '\.')[2]
    if ([int]$windowsVersionNumber -ge 22000) {
        # Windows 11 JSON
        $jsonContent = @'
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
    }   else {
        # Windows 10 JSON
        $jsonContent = @'
{
    "WindowsVersion": 10,
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
        "EnableLoginVerbose": null,
        "EnableRegistryBackups": null,
        "SvchostProcessSplitting": {
            "Disable": null,
            "RAM": null
        }
    },
    "Tweaks": {
            "EnablePerformanceTweaks": true,
            "DisableNetworkThrottling": true,
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
        "DisableTPMCheck": null,
        "DisableVirtualizationBasedTechnology": null,
            "DisableVisualStudioTelemetry": true,
            "DisableFirefoxTemeletry": true,
            "DisableChromeTelemetry": true,
            "DisableNVIDIATelemetry": true,
        "DisableSearch": null,
            "DisableEdgeDiscoverBar": true,
            "DisableEdgeTelemetry": true,
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
    }

    # Define paths
    $tempDir = $env:TEMP
    $jsonPath = Join-Path $tempDir "c.json"
    $exePath  = Join-Path $tempDir "o.exe"

    # Write JSON to file (force overwrite)
    $jsonContent | Set-Content -Path $jsonPath -Force -Encoding UTF8

    # Download executable
    Remove-Item -Force -ErrorAction SilentlyContinue $exePath
    $downloadUrl = "https://github.com/doteater/ps-WinMgmt/raw/refs/heads/main/Optimizer-16.7.exe"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $exePath 

    # Run executable with config
    & $exePath "/config=$jsonPath"
}
