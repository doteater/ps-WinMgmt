function Set-NoSleepMode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [bool]$Enable
    )

    if ($Enable) {
        # Look for an existing "No Sleep Mode" plan
        $guid = powercfg /list | Select-String "No Sleep Mode" | ForEach-Object {
            if ($_ -match '\b[A-Fa-f0-9-]{36}\b') { $matches[0] }
        } | Select-Object -First 1

        if (-not $guid) {
            # None found, create a new one
            $guid = (powercfg /duplicatescheme SCHEME_CURRENT) -match '\b[A-Fa-f0-9-]{36}\b' | ForEach-Object { $matches[0] }
            powercfg /changename $guid "No Sleep Mode" "Custom plan that prevents sleep"
        }

        # Activate the plan
        powercfg /setactive $guid

        # Ensure sleep/hibernate are disabled
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
