function Update-Locale {
    [CmdletBinding()]
    param(
        #[Parameter(Mandatory = $true)]
        #[bool]$Enable
    )
    Write-Host "=== Update-Locale Script ==="
    Write-Host "installing language"
    Install-Language -Language en-US

    Write-Host "set system locale, ui language"
    Set-WinSystemLocale en-US
    Set-SystemPreferredUILanguage -Language en-US
    Set-WinUserLanguageList en-US -Force
    
    Write-Host "apply to new users"
    Copy-UserInternationalSettingsToSystem -WelcomeScreen $true -NewUser $true

}
