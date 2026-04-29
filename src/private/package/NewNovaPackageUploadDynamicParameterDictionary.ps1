function New-NovaPackageUploadDynamicParameterDictionary {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'This helper only returns runtime parameter metadata and does not mutate state.')]
    [CmdletBinding()]
    param()

    $dictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()
    foreach ($definition in @(
        @{Name = 'UploadPath'; Type = [string]}
        @{Name = 'Headers'; Type = [hashtable]}
        @{Name = 'Token'; Type = [string]}
        @{Name = 'TokenEnvironmentVariable'; Type = [string]}
        @{Name = 'AuthenticationScheme'; Type = [string]}
    )) {
        $attributeCollection = [System.Collections.ObjectModel.Collection[System.Attribute]]::new()
        $attributeCollection.Add([System.Management.Automation.ParameterAttribute]::new())
        $parameter = [System.Management.Automation.RuntimeDefinedParameter]::new($definition.Name, $definition.Type, $attributeCollection)
        $dictionary.Add($definition.Name, $parameter)
    }

    return $dictionary
}
