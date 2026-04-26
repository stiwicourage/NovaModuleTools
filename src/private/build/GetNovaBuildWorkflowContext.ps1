function Get-NovaBuildWorkflowContext {
    [CmdletBinding()]
    param(
        [pscustomobject]$ProjectInfo,
        [switch]$ContinuousIntegrationRequested
    )

    $projectInfo = Get-NovaBuildProjectInfo -ProjectInfo $ProjectInfo

    return [pscustomobject]@{
        ProjectInfo = $projectInfo
        ContinuousIntegrationRequested = [bool]$ContinuousIntegrationRequested
        Target = $projectInfo.OutputModuleDir
        Operation = 'Build Nova module output'
    }
}

