function Get-NovaDynamicParameterAttributeCollection {
    [CmdletBinding()]
    param(
        [string[]]$ParameterSetNameList = @(),
        [switch]$Mandatory
    )

    $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
    if ($ParameterSetNameList.Count -eq 0) {
        $attribute = [System.Management.Automation.ParameterAttribute]::new()
        $attribute.Mandatory = [bool]$Mandatory
        $attributeCollection.Add($attribute)
        return $attributeCollection
    }

    foreach ($parameterSetName in $ParameterSetNameList) {
        $attribute = [System.Management.Automation.ParameterAttribute]::new()
        $attribute.ParameterSetName = $parameterSetName
        $attribute.Mandatory = [bool]$Mandatory
        $attributeCollection.Add($attribute)
    }

    return $attributeCollection
}

function Add-NovaDynamicTypedParameter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Management.Automation.RuntimeDefinedParameterDictionary]$ParameterDictionary,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][type]$ParameterType,
        [string[]]$ParameterSetNameList = @(),
        [switch]$Mandatory
    )

    $attributeCollection = Get-NovaDynamicParameterAttributeCollection -ParameterSetNameList $ParameterSetNameList -Mandatory:$Mandatory
    $runtimeParameter = [System.Management.Automation.RuntimeDefinedParameter]::new($Name, $ParameterType, $attributeCollection)
    $ParameterDictionary.Add($Name, $runtimeParameter)
}

function Get-NovaDynamicDeliveryParameterDictionary {
    [CmdletBinding()]
    param()

    $parameterDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
    Add-NovaDynamicTypedParameter -ParameterDictionary $parameterDictionary -Name 'SkipTests' -ParameterType ([switch])
    Add-NovaDynamicTypedParameter -ParameterDictionary $parameterDictionary -Name 'ContinuousIntegration' -ParameterType ([switch])
    Add-NovaDynamicTypedParameter -ParameterDictionary $parameterDictionary -Name 'OverrideWarning' -ParameterType ([switch])
    return $parameterDictionary
}

function Get-NovaDynamicOverrideWarningParameterDictionary {
    [CmdletBinding()]
    param()

    $parameterDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
    Add-NovaDynamicTypedParameter -ParameterDictionary $parameterDictionary -Name 'OverrideWarning' -ParameterType ([switch])
    return $parameterDictionary
}

function Get-NovaDynamicReleaseParameterDictionary {
    [CmdletBinding()]
    param()

    $parameterDictionary = Get-NovaDynamicDeliveryParameterDictionary
    Add-NovaDynamicTypedParameter -ParameterDictionary $parameterDictionary -Name 'Path' -ParameterType ([string]) -ParameterSetNameList @('Local', 'Repository', 'PublishOption')
    # TODO: Remove the legacy PublishOption dynamic parameter this was deprecated on: 2026-05-03.
    Add-NovaDynamicTypedParameter -ParameterDictionary $parameterDictionary -Name 'PublishOption' -ParameterType ([hashtable]) -ParameterSetNameList @('PublishOption') -Mandatory
    return $parameterDictionary
}
