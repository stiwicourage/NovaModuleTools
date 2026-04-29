function Get-NovaModulePsDataValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [object]$Module = $ExecutionContext.SessionState.Module
    )

    $psData = $Module.PrivateData.PSData
    if ($psData -is [hashtable]) {
        return $psData[$Name]
    }

    if ($null -eq $psData) {
        return $null
    }

    $property = $psData.PSObject.Properties[$Name]
    if ($null -eq $property) {
        return $null
    }

    return $property.Value
}
