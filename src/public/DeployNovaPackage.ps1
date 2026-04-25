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

        $shouldRun = if (-not $WhatIfPreference -and (Test-NovaPackageUploadExplicitConfirmEnabled -BoundParameters $PSBoundParameters)) {
            Confirm-NovaPackageUploadAction -WorkflowContext $workflowContext -HostUi $Host.UI
        }
        else {
            $PSCmdlet.ShouldProcess($workflowContext.Target, $workflowContext.Operation)
        }

        if (-not $shouldRun) {
            return @()
        }

        return @(Invoke-NovaPackageUploadWorkflow -WorkflowContext $workflowContext -UploadArtifactList $workflowContext.UploadArtifactList)
    }
}

