function New-NovaTestDynamicParameterDictionary {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'This helper only returns runtime parameter metadata and does not mutate state.')]
    [CmdletBinding()]
    param()

    $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
    $attributeCollection.Add([System.Management.Automation.ParameterAttribute]::new())
    $dictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
    $dictionary.Add('Build',[System.Management.Automation.RuntimeDefinedParameter]::new('Build', [switch],$attributeCollection))
    return $dictionary
}
