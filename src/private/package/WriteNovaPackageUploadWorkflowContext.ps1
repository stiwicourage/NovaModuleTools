function Write-NovaPackageUploadWorkflowContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $message = Get-NovaPackageUploadWorkflowContextMessage -WorkflowContext $WorkflowContext
    if ($null -ne $message) {
        Write-Host $message
    }

    if (-not [string]::IsNullOrWhiteSpace($WorkflowContext.Target)) {
        Write-Verbose "Target: $( $WorkflowContext.Target )"
    }
}

function Get-NovaPackageUploadWorkflowContextMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $artifactCount = @($WorkflowContext.UploadArtifactList).Count
    if ($artifactCount -eq 0) {
        return $null
    }

    if ($artifactCount -eq 1) {
        return "$( $WorkflowContext.Operation )."
    }

    return "Ready to upload $artifactCount package artifacts."
}
