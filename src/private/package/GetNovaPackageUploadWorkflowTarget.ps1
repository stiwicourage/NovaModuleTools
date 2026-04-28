function Get-NovaPackageUploadWorkflowTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$UploadArtifactList
    )

    return ($UploadArtifactList | ForEach-Object {$_.UploadUrl}) -join ', '
}
