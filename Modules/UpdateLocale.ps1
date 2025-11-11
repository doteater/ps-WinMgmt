function Update-Locale {
    [CmdletBinding()]
    #param(
        #[Parameter(Mandatory = $true)]
        #[bool]$Enable
    #)
    Install-Language -Language en-US


    Set-WinSystemLocale en-US
    Set-SystemPreferredUILanguage -Language en-US
    Set-WinUserLanguageList en-US -Force
    
    
    Copy-UserInternationalSettingsToSystem -WelcomeScreen $true -NewUser $true

}
