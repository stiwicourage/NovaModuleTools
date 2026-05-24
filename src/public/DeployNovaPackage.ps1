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

        Write-NovaPackageUploadWorkflowContext -WorkflowContext $workflowContext

        $shouldRun = $PSCmdlet.ShouldProcess($workflowContext.Target, $workflowContext.Operation)

        if (-not $shouldRun) {
            return @()
        }

        $result = @(Invoke-NovaPackageUploadWorkflow -WorkflowContext $workflowContext -UploadArtifactList $workflowContext.UploadArtifactList)
        Write-NovaPackageUploadResultOutput -Result $result

        return $result
    }
}
