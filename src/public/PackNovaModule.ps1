function Pack-NovaModule {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseApprovedVerbs', '', Justification = 'Pack is the required public workflow verb and matches the nova pack CLI command.')]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $moduleContext = $ExecutionContext.SessionState.Module
    $workflowParams = Get-NovaShouldProcessForwardingParameter -WhatIfEnabled:$WhatIfPreference
    $projectInfo = Get-NovaProjectInfo
    $packageMetadata = Get-NovaPackageMetadata -ProjectInfo $projectInfo
    Assert-NovaPackageMetadata -PackageMetadata $packageMetadata

    Invoke-NovaBuild @workflowParams
    Test-NovaBuild @workflowParams

    if (-not $PSCmdlet.ShouldProcess($packageMetadata.PackagePath, 'Create NuGet package from built module output')) {
        return
    }

    $packageHelper = Get-Command -Name New-NovaPackageArtifact -CommandType Function -ErrorAction SilentlyContinue
    if ($null -ne $packageHelper) {
        return New-NovaPackageArtifact -ProjectInfo $projectInfo -PackageMetadata $packageMetadata
    }

    $packagingModule = Import-Module $moduleContext.Path -Force -DisableNameChecking -PassThru
    $packageCreation = {
        param($ProjectInfo, $PackageMetadata)

        New-NovaPackageArtifact -ProjectInfo $ProjectInfo -PackageMetadata $PackageMetadata
    }

    return & $packagingModule $packageCreation $projectInfo $packageMetadata
}

