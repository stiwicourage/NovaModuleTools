function Get-NovaPackageSettingValue {param($InputObject, $Name)
    if ($null -eq $InputObject) {return $null}
    if ($InputObject -is [System.Collections.IDictionary]) {return $InputObject[$Name]}
    if ($InputObject.PSObject.Properties.Name -contains $Name) {return $InputObject.$Name}
    return $null
}
function ConvertTo-NovaPackageLatestPolicy {param($Value) return ("$Value").ToLowerInvariant()}
function Get-NovaPackageMetadata {param($ProjectInfo, $PackageType, [switch]$Latest)
    return [pscustomobject]@{Type=$PackageType; Latest=[bool]$Latest}
}
