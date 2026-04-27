function Get-NovaCliSwitchOptionName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$TokenMap,
        [Parameter(Mandatory)][string]$Token
    )

    $optionName = $TokenMap[$Token]
    if ( [string]::IsNullOrWhiteSpace($optionName)) {
        Stop-NovaOperation -Message "Unknown argument: $Token" -ErrorId 'Nova.Validation.UnknownCliArgument' -Category InvalidArgument -TargetObject $Token
    }

    return $optionName
}

function ConvertFrom-NovaCliSwitchArgument {
    [CmdletBinding()]
    param(
        [string[]]$Arguments,
        [Parameter(Mandatory)][hashtable]$TokenMap
    )

    $Arguments = ConvertTo-NovaCliArgumentArray -BoundParameters $PSBoundParameters -Arguments $Arguments
    $options = @{}
    foreach ($token in $Arguments) {
        $options[(Get-NovaCliSwitchOptionName -TokenMap $TokenMap -Token $token)] = $true
    }

    return $options
}
