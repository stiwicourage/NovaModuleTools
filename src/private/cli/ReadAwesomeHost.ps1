
function Read-AwesomeHost {
    [CmdletBinding()]
    param (
        [Parameter()]
        [object]
        $Ask
    )

    $hostUi = Get-AwesomeHostUi
    $hasChoice = $false
    if ($Ask -is [System.Collections.IDictionary]) {
        $hasChoice = $Ask.Contains('Choice') -and $null -ne $Ask['Choice']
    }
    else {
        $choiceProperty = $Ask.PSObject.Properties['Choice']
        $hasChoice = $null -ne $choiceProperty -and $null -ne $choiceProperty.Value
    }

    if (-not $hasChoice) {
        return Read-AwesomeStandardPrompt -Ask $Ask -HostUi $hostUi
    }

    return Read-AwesomeChoicePrompt -Ask $Ask -HostUi $hostUi
}
