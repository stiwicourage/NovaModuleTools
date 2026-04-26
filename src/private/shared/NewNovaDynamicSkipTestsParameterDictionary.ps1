function New-NovaDynamicSkipTestsParameterDictionary {
    [CmdletBinding()]
    param()

    $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
    $attributeCollection.Add([System.Management.Automation.ParameterAttribute]::new())
    $runtimeParameter = [System.Management.Automation.RuntimeDefinedParameter]::new('SkipTests', [switch],$attributeCollection)
    $parameterDictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
    $parameterDictionary.Add('SkipTests', $runtimeParameter)
    return $parameterDictionary
}

