function Get-AwesomePromptValue {
    param(
        [Parameter(Mandatory)][object]$Ask,
        [Parameter(Mandatory)][string]$Name
    )

    if ($Ask -is [System.Collections.IDictionary]) {
        if ( $Ask.Contains($Name)) {
            return $Ask[$Name]
        }

        return $null
    }

    $property = $Ask.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}

