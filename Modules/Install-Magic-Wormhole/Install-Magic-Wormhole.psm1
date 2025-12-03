function install-Magic-Wormhole {
    #C:\Windows\System32\config\systemprofile\AppData\Local\Microsoft\WinGet\Links\wormhole.exe -> C:\WINDOWS\system32\config\systemprofile\AppData\Local\Microsoft\WinGet\Packages\magic-wormhole.magic-wormhole_Microsoft.Winget.Source_8wekyb3d8bbwe\wormhole.exe


    $wormholeInstalled = Get-ItemProperty -Path C:\Windows\System32\config\systemprofile\AppData\Local\Microsoft\WinGet\Links\wormhole.exe -ErrorAction SilentlyContinue
    $wingetInstalled = Get-ItemProperty -Path C:\ProgramData\Microsoft.DesktopAppInstaller\winget.exe -ErrorAction SilentlyContinue


    if($wormholeInstalled) {
        write "wormhole already installed @ C:\Windows\System32\config\systemprofile\AppData\Local\Microsoft\WinGet\Links\wormhole.exe"
        return 
    } elseif (-Not $wingetInstalled)  {
        write "installing winget first..."
        $wgfunctioninstalled = Get-Command install-winget-for-system -Type Function -ErrorAction SilentlyContinue
        if($wgfunctioninstalled) {
            Set-ExecutionPolicy Unrestricted -scope process
            install-winget-for-system
        } else {
            write "sc winget module not found, (re)installing sc modules"
            irm tiny.cc/scmain | iex
            Set-ExecutionPolicy Unrestricted -scope process
            install-winget-for-system
        }
    }
    $mycmd = 'C:\ProgramData\Microsoft.DesktopAppInstaller\winget.exe' 
    $myargs = 'install magic-wormhole --scope machine --accept-package-agreements --accept-source-agreements --silent --force'
    write "wormhole not installed, found winget, installing with $mycmd $myargs"
    Start-Process -FilePath $mycmd  -ArgumentList $myargs -wait -NoNewWindow
    write "^^ IGNORE the restarting shell to update PATH, I did it for you ;) just type 'wormhole' now and press enter!!!!!"
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}




    #    if($wormholeInstalled) {
    #    write "wormhole already installed @ C:\Windows\System32\config\systemprofile\AppData\Local\Microsoft\WinGet\Links\wormhole.exe"
    #    $Global:winget = "${env:ProgramData}\\Microsoft.DesktopAppInstaller\\WinGet.exe"
    #    Write-Host "WinGet available at $Global:winget"
    #    return 
    #}
    #Get-Comma
#
#
#
    #Get-Command install-winget-for-system -Type Function -ErrorAction SilentlyContinue




