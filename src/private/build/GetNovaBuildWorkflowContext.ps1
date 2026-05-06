function Get-NovaBuildWorkflowContext {
    [CmdletBinding()]
    param(
        [pscustomobject]$ProjectInfo,
        [switch]$ContinuousIntegrationRequested,
        [switch]$OverrideWarningRequested
    )

    $projectInfo = Get-NovaBuildProjectInfo -ProjectInfo $ProjectInfo

    return [pscustomobject]@{
        ProjectInfo = $projectInfo
        ContinuousIntegrationRequested = [bool]$ContinuousIntegrationRequested
        OverrideWarningRequested = [bool]$OverrideWarningRequested
        Target = $projectInfo.OutputModuleDir
        Operation = 'Build Nova module output'
    }
}
