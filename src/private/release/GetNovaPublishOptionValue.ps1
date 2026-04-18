function Get-NovaPublishOptionValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$PublishOption,
        [Parameter(Mandatory)][string]$Name
    )

    if (-not $PublishOption.ContainsKey($Name)) {
        return $null
    }

    return $PublishOption[$Name]
}
