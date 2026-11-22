function Get-NovaPackageUploadWorkflowOperation {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][object[]]$UploadArtifactList
    )

    if ($UploadArtifactList.Count -eq 1) {
        return "Upload $( $UploadArtifactList[0].Type ) package artifact $( $UploadArtifactList[0].PackageFileName )"
    }

    return "Upload $( $UploadArtifactList.Count ) package artifacts"
}
