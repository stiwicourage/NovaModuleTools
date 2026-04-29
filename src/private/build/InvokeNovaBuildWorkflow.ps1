function Invoke-NovaBuildWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $projectInfo = $WorkflowContext.ProjectInfo
    $continuousIntegrationRequested = ($WorkflowContext.PSObject.Properties.Name -contains 'ContinuousIntegrationRequested') -and $WorkflowContext.ContinuousIntegrationRequested

    Reset-ProjectDist -ProjectInfo $projectInfo -Confirm:$false
    Build-Module -ProjectInfo $projectInfo
    Invoke-NovaBuildDuplicateValidation -ProjectInfo $projectInfo
    Build-Manifest -ProjectInfo $projectInfo
    Build-Help -ProjectInfo $projectInfo
    Copy-ProjectResource -ProjectInfo $projectInfo
    Invoke-NovaBuildUpdateNotificationSafely

    if ($continuousIntegrationRequested) {
        $null = Import-NovaBuiltModuleForCi -ProjectInfo $projectInfo
    }
}

function Invoke-NovaBuildDuplicateValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo
    )

    if (-not $ProjectInfo.FailOnDuplicateFunctionNames) {
        return
    }

    Assert-BuiltModuleHasNoDuplicateFunctionName -ProjectInfo $ProjectInfo
}

function Invoke-NovaBuildUpdateNotificationSafely {
    [CmdletBinding()]
    param()

    try {
        Invoke-NovaBuildUpdateNotification
    }
    catch {
        $null = $_
    }
}
