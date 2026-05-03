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

function Add-NovaDynamicSwitchParameter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Management.Automation.RuntimeDefinedParameterDictionary]$ParameterDictionary,
        [Parameter(Mandatory)][string]$Name,
        [string[]]$ParameterSetNameList = @(),
        [switch]$Mandatory
    )

    $attributeCollection = Get-NovaDynamicParameterAttributeCollection -ParameterSetNameList $ParameterSetNameList -Mandatory:$Mandatory
    $runtimeParameter = [System.Management.Automation.RuntimeDefinedParameter]::new($Name, [switch],$attributeCollection)
    $ParameterDictionary.Add($Name, $runtimeParameter)
}

function Add-NovaDynamicStringParameter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Management.Automation.RuntimeDefinedParameterDictionary]$ParameterDictionary,
        [Parameter(Mandatory)][string]$Name,
        [string[]]$ParameterSetNameList = @(),
        [switch]$Mandatory
    )

    $attributeCollection = Get-NovaDynamicParameterAttributeCollection -ParameterSetNameList $ParameterSetNameList -Mandatory:$Mandatory
    $runtimeParameter = [System.Management.Automation.RuntimeDefinedParameter]::new($Name, [string],$attributeCollection)
    $ParameterDictionary.Add($Name, $runtimeParameter)
}

function Add-NovaDynamicHashtableParameter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][System.Management.Automation.RuntimeDefinedParameterDictionary]$ParameterDictionary,
        [Parameter(Mandatory)][string]$Name,
        [string[]]$ParameterSetNameList = @(),
        [switch]$Mandatory
    )

    $attributeCollection = Get-NovaDynamicParameterAttributeCollection -ParameterSetNameList $ParameterSetNameList -Mandatory:$Mandatory
    $runtimeParameter = [System.Management.Automation.RuntimeDefinedParameter]::new($Name, [hashtable],$attributeCollection)
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

function Get-NovaDynamicReleaseParameterDictionary {
    [CmdletBinding()]
    param()

    $parameterDictionary = Get-NovaDynamicDeliveryParameterDictionary
    Add-NovaDynamicStringParameter -ParameterDictionary $parameterDictionary -Name 'Path' -ParameterSetNameList @('Local', 'Repository', 'PublishOption')
    # TODO: Remove the legacy PublishOption dynamic parameter this was deprecated on: 2026-05-03.
    Add-NovaDynamicHashtableParameter -ParameterDictionary $parameterDictionary -Name 'PublishOption' -ParameterSetNameList @('PublishOption') -Mandatory
    return $parameterDictionary
}

