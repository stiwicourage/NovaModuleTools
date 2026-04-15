function Invoke-NovaRelease {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [hashtable]$PublishOption = @{},
        [string]$Path = (Get-Location).Path
    )

    Push-Location -LiteralPath $Path
    try {
        $projectInfo = Get-NovaProjectInfo
        $workflowParams = Get-NovaShouldProcessForwardingParameter -WhatIfEnabled:$WhatIfPreference
        $repository = Get-NovaPublishOptionValue -PublishOption $PublishOption -Name Repository
        $moduleDirectoryPath = Get-NovaPublishOptionValue -PublishOption $PublishOption -Name ModuleDirectoryPath
        $apiKey = Get-NovaPublishOptionValue -PublishOption $PublishOption -Name ApiKey
        $publishInvocation = Resolve-NovaPublishInvocation -ProjectInfo $projectInfo -Repository $repository -ModuleDirectoryPath $moduleDirectoryPath -ApiKey $apiKey

        Write-NovaLocalWorkflowMode -WorkflowName release -LocalRequested:($PublishOption.ContainsKey('Local') -and $PublishOption.Local)

        $releaseOperation = Get-NovaPublishWorkflowOperation -IsLocal:$publishInvocation.IsLocal -Release

        $shouldRun = $PSCmdlet.ShouldProcess($publishInvocation.Target, $releaseOperation)
        if (-not $shouldRun -and -not $WhatIfPreference) {
            return
        }

        Invoke-NovaBuild @workflowParams
        Test-NovaBuild @workflowParams
        $versionResult = Update-NovaModuleVersion @workflowParams
        Invoke-NovaBuild @workflowParams

        $publishParams = @{}
        foreach ($parameterName in $publishInvocation.Parameters.Keys) {
            $publishParams[$parameterName] = $publishInvocation.Parameters[$parameterName]
        }

        foreach ($parameterName in $workflowParams.Keys) {
            $publishParams[$parameterName] = $workflowParams[$parameterName]
        }

        & $publishInvocation.Action @publishParams

        return $versionResult
    }
    catch {
        throw
    }
    finally {
        Pop-Location
    }
}



