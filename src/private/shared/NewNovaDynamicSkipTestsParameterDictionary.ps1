function Add-NovaDynamicSwitchParameter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Management.Automation.RuntimeDefinedParameterDictionary]$ParameterDictionary,
        [Parameter(Mandatory)][string]$Name
    )

    $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
    $attributeCollection.Add([System.Management.Automation.ParameterAttribute]::new())
    $runtimeParameter = [System.Management.Automation.RuntimeDefinedParameter]::new($Name, [switch],$attributeCollection)
    $ParameterDictionary.Add($Name, $runtimeParameter)
}

function Get-NovaDynamicDeliveryParameterDictionary {
    [CmdletBinding()]
    param()

    $parameterDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
    Add-NovaDynamicSwitchParameter -ParameterDictionary $parameterDictionary -Name 'SkipTests'
    Add-NovaDynamicSwitchParameter -ParameterDictionary $parameterDictionary -Name 'ContinuousIntegration'
    return $parameterDictionary
}
