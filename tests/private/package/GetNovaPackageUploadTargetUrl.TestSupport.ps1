function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
function Get-NovaPackageSettingValue {param($InputObject, $Name)
    if ($null -eq $InputObject) {return $null}
    if ($InputObject -is [System.Collections.IDictionary]) {return $InputObject[$Name]}
    $prop = $InputObject.PSObject.Properties[$Name]
    if ($null -eq $prop) {return $null}
    return $prop.Value
}
function Get-NovaFirstConfiguredValue {param($CandidateList)
    foreach ($c in $CandidateList) {if (-not [string]::IsNullOrWhiteSpace("$c")) {return $c}}
    return $null
}
function Test-NovaConfiguredValue {param($Value) return -not [string]::IsNullOrWhiteSpace("$Value")}
