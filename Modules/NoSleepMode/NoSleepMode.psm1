function Set-NoSleepMode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Enable
    )

    if ($Enable) {
        $guid = (powercfg /duplicatescheme SCHEME_CURRENT) -match '\b[A-Fa-f0-9-]{36}\b' | ForEach-Object { $matches[0] }
        powercfg /changename $guid "No Sleep Mode" "Custom plan that prevents sleep"
        powercfg /setactive $guid
        powercfg /change standby-timeout-ac 0
        powercfg /change standby-timeout-dc 0
        powercfg /change hibernate-timeout-ac 0
        powercfg /change hibernate-timeout-dc 0
        Write-Verbose "No Sleep Mode enabled."
    }
    else {
        powercfg /setactive SCHEME_BALANCED
        Write-Verbose "Balanced power plan restored."
    }
}
