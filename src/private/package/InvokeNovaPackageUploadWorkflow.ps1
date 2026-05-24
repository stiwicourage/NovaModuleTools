function Invoke-NovaPackageUploadWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [object[]]$UploadArtifactList = @()
    )

    $resolvedUploadArtifactList = @(Get-NovaResolvedPackageUploadArtifactList -WorkflowContext $WorkflowContext -UploadArtifactList $UploadArtifactList)
    if ($resolvedUploadArtifactList.Count -eq 0) {
        return @()
    }

    $uploadResult = @()
    $artifactCount = $resolvedUploadArtifactList.Count
    try {
        for ($index = 0; $index -lt $artifactCount; $index++) {
            $uploadArtifact = $resolvedUploadArtifactList[$index]
            Write-NovaPackageUploadProgress -UploadArtifact $uploadArtifact -CurrentIndex ($index + 1) -TotalCount $artifactCount
            $uploadResult += Invoke-NovaPackageArtifactUpload -UploadArtifact $uploadArtifact
        }
    } finally {
        Complete-NovaPackageUploadProgress
    }

    return $uploadResult
}

function Get-NovaResolvedPackageUploadArtifactList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext,
        [object[]]$UploadArtifactList = @()
    )

    if (@($UploadArtifactList).Count -gt 0) {
        return @($UploadArtifactList)
    }

    return @($WorkflowContext.UploadArtifactList)
}

function Write-NovaPackageUploadProgress {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$UploadArtifact,
        [Parameter(Mandatory)][int]$CurrentIndex,
        [Parameter(Mandatory)][int]$TotalCount
    )

    $percentComplete = [int](($CurrentIndex - 1) * 100 / $TotalCount)
    $status = "Uploading $( $UploadArtifact.PackageFileName ) ($CurrentIndex of $TotalCount)"
    if ([string]::IsNullOrWhiteSpace([string]$UploadArtifact.PackageFileName)) {
        $status = "Uploading artifact $CurrentIndex of $TotalCount"
    }

    Write-Progress -Activity 'Uploading package artifacts' -Status $status -PercentComplete $percentComplete
}

function Complete-NovaPackageUploadProgress {
    [CmdletBinding()]
    param()

    Write-Progress -Activity 'Uploading package artifacts' -Completed
}
