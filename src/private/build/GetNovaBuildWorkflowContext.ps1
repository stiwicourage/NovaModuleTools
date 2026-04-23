function Get-NovaBuildWorkflowContext {
    [CmdletBinding()]
    param(
        [pscustomobject]$ProjectInfo
    )

    $projectInfo = Get-NovaBuildProjectInfo -ProjectInfo $ProjectInfo

    return [pscustomobject]@{
        ProjectInfo = $projectInfo
        Target = $projectInfo.OutputModuleDir
        Operation = 'Build Nova module output'
    }
}

