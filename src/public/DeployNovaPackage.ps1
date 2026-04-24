function Deploy-NovaPackage {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [string[]]$PackagePath,
        [string[]]$PackageType,
        [string]$Url,
        [string]$Repository
    )

    dynamicparam {
        return New-NovaPackageUploadDynamicParameterDictionary
    }

    end {
        $projectInfo = Get-NovaProjectInfo
        $uploadOption = New-NovaPackageUploadOption -BoundParameters $PSBoundParameters
        $workflowContext = Get-NovaPackageUploadWorkflowContext -BoundParameters $PSBoundParameters -ProjectInfo $projectInfo -UploadOption $uploadOption
        $approvedUploadArtifactList = @(
        foreach ($uploadArtifact in $workflowContext.UploadArtifactList) {
            $uploadAction = "Upload $( $uploadArtifact.Type ) package artifact $( $uploadArtifact.PackageFileName )"
            if (-not $PSCmdlet.ShouldProcess($uploadArtifact.UploadUrl, $uploadAction)) {
                continue
            }

            $uploadArtifact
        }
        )

        return @(Invoke-NovaPackageUploadWorkflow -WorkflowContext $workflowContext -UploadArtifactList $approvedUploadArtifactList)
    }
}

