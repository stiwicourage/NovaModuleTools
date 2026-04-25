function Get-NovaPackageUploadWorkflowContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$BoundParameters,
        [pscustomobject]$ProjectInfo,
        [pscustomobject]$UploadOption
    )

    $resolvedProjectInfo = if ($null -ne $ProjectInfo) {
        $ProjectInfo
    }
    else {
        Get-NovaProjectInfo
    }
    $resolvedUploadOption = if ($null -ne $UploadOption) {
        $UploadOption
    }
    else {
        New-NovaPackageUploadOption -BoundParameters $BoundParameters
    }

    $uploadArtifactList = @(Resolve-NovaPackageUploadInvocation -ProjectInfo $resolvedProjectInfo -UploadOption $resolvedUploadOption)

    return [pscustomobject]@{
        ProjectInfo = $resolvedProjectInfo
        UploadOption = $resolvedUploadOption
        UploadArtifactList = $uploadArtifactList
        Target = Get-NovaPackageUploadWorkflowTarget -UploadArtifactList $uploadArtifactList
        Operation = Get-NovaPackageUploadWorkflowOperation -UploadArtifactList $uploadArtifactList
    }
}

