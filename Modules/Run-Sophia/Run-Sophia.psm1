set-executionpolicy unrestricted -scope process
function Run-Sophia {
    #$sophiazip = "sc-sophia-7.1.5-260416.4.zip"
    #$sophiazip = "sc-sophia-7.1.6-260625.3.zip"
    $sophiazip = "sc-sophia-260625.8.zip"
    $ep = get-executionpolicy
    
    #write "ep: $ep"
    
    #Start-Transcript "$env:TEMP\sophia.log"
    $DebugPreference = 'Continue'
    
    
    $tempFile = [System.IO.Path]::GetTempFileName() + '.ps1'
    Invoke-WebRequest -Uri 'https://github.com/doteater/ps-WinMgmt/raw/refs/heads/main/Modules/Run-Sophia/Run-Sophia.psm1' -OutFile $tempFile
    
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
    
    
    $URL = "https://github.com/doteater/ps-WinMgmt/raw/refs/heads/main/$sophiazip"
    $filename = "$env:TEMP\s.zip"
    irm $URL -o $filename
    $timestamp = Get-Date -Format "yyyyMMddHHmmss"
    expand-archive $filename -destinationpath $timestamp
    get-childitem -recurse .\$timestamp | unblock-file
    #cd $timestamp\Sophia.Script.for.Windows.11.*\Sophia_Script_for_Windows_11_*
    cd $timestamp
    set-executionpolicy unrestricted -scope process

    .\sophia.ps1
}
