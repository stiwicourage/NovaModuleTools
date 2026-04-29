function Get-NovaManifestValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Manifest,
        [Parameter(Mandatory)][string]$Name
    )

    if ($Manifest -is [System.Collections.IDictionary]) {
        return $Manifest[$Name]
    }

    $property = $Manifest.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}
