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

    return [pscustomobject]@{
        ProjectInfo = $resolvedProjectInfo
        UploadOption = $resolvedUploadOption
        UploadArtifactList = @(Resolve-NovaPackageUploadInvocation -ProjectInfo $resolvedProjectInfo -UploadOption $resolvedUploadOption)
    }
}

