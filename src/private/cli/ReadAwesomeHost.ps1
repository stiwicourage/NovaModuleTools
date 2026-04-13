
function Read-AwesomeHost {
    [CmdletBinding()]
    param (
        [Parameter()]
        [pscustomobject]
        $Ask
    )

    $hostUi = Get-AwesomeHostUi
    if ($null -eq $Ask.Choice) {
        return Read-AwesomeStandardPrompt -Ask $Ask -HostUi $hostUi
    }

    return Read-AwesomeChoicePrompt -Ask $Ask -HostUi $hostUi
}
