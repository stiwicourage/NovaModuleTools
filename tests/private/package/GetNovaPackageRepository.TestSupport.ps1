function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
function Get-NovaPackageSettingValue {param($InputObject, $Name)
    if ($null -eq $InputObject) {return $null}
    if ($InputObject -is [System.Collections.IDictionary]) {return $InputObject[$Name]}
    return $InputObject.$Name
}
