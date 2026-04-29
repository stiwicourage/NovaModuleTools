function Invoke-NovaPester {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Configuration
    )

    return Invoke-Pester -Configuration $Configuration
}
