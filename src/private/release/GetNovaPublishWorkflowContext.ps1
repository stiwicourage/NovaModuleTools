function Get-NovaPublishWorkflowContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][hashtable]$PublishOption,
        [hashtable]$WorkflowParams = @{},
        [Parameter(Mandatory)][hashtable]$WorkflowSettings
    )

    $repository = Get-NovaPublishOptionValue -PublishOption $PublishOption -Name Repository
    $moduleDirectoryPath = Get-NovaPublishOptionValue -PublishOption $PublishOption -Name ModuleDirectoryPath
    $apiKey = Get-NovaPublishOptionValue -PublishOption $PublishOption -Name ApiKey
    $skipTestsRequested = [bool](Get-NovaPublishOptionValue -PublishOption $PublishOption -Name SkipTests)
    $includeLocalPublishActivation = $WorkflowSettings.ContainsKey('IncludeLocalPublishActivation') -and $WorkflowSettings.IncludeLocalPublishActivation
    $release = $WorkflowSettings.ContainsKey('Release') -and $WorkflowSettings.Release
    $publishInvocation = Resolve-NovaPublishInvocation -ProjectInfo $ProjectInfo -Repository $repository -ModuleDirectoryPath $moduleDirectoryPath -ApiKey $apiKey

    $localPublishActivation = $null
    if ($includeLocalPublishActivation) {
        $localPublishActivation = Get-NovaLocalPublishActivation -PublishInvocation $publishInvocation
    }

    return [pscustomobject]@{
        WorkflowName = $WorkflowSettings.WorkflowName
        LocalRequested = [bool]($PublishOption.ContainsKey('Local') -and $PublishOption.Local)
        WorkflowParams = $WorkflowParams
        SkipTestsRequested = $skipTestsRequested
        PublishInvocation = $publishInvocation
        PublishParams = Get-NovaResolvedPublishParameterMap -PublishInvocation $publishInvocation -WorkflowParams $WorkflowParams
        LocalPublishActivation = $localPublishActivation
        Target = $publishInvocation.Target
        Operation = Get-NovaPublishWorkflowOperation -IsLocal:$publishInvocation.IsLocal -Release:$release -SkipTestsRequested:$skipTestsRequested
    }
}
