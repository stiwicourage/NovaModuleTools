function ConvertFrom-NovaPSModuleUpdateResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Result
    )

    if ($Result.Outcome -notin @('Installed', 'AlreadyInstalled')) {
        throw "PSModuleUpdate did not install the update (outcome: $( $Result.Outcome ))."
    }

    return [pscustomobject]@{
        InstalledVersion = $Result.InstalledVersion
        RestartRequired = [bool]$Result.RestartRequired
    }
}
