set-executionpolicy unrestricted -scope process
function Run-Sophia {
    $ep = get-executionpolicy
    
    write "ep: $ep"
    
    Start-Transcript C:\windows\temp\sophia.log
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
    
    
    $URL = 'https://github.com/doteater/ps-WinMgmt/raw/refs/heads/main/sc-sofia-7.1.1-260217.zip'
    $filename = 'C:\windows\temp\s.zip'
    irm $URL -o $filename
    expand-archive $filename
    get-childitem -recurse .\s | unblock-file
    cd s\sc-sofia*\Sophia.Script.for.Windows.11*\Sophia_Script_for_Windows_11*
    .\sophia.ps1
}
