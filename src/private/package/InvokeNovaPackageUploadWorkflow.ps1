function Invoke-NovaPackageUploadWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [object[]]$UploadArtifactList = @()
    )

    $resolvedUploadArtifactList = @($UploadArtifactList)
    if ($resolvedUploadArtifactList.Count -eq 0 -and @($WorkflowContext.UploadArtifactList).Count -eq 0) {
        return @()
    }

    return @(
    $resolvedUploadArtifactList | ForEach-Object {
        Invoke-NovaPackageArtifactUpload -UploadArtifact $_
    }
    )
}
