function New-NovaModulePackage {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $moduleContext = $ExecutionContext.SessionState.Module
    $workflowParams = Get-NovaShouldProcessForwardingParameter -WhatIfEnabled:$WhatIfPreference
    $projectInfo = Get-NovaProjectInfo
    $packageMetadataList = @(Get-NovaPackageMetadataList -ProjectInfo $projectInfo)
    foreach ($packageMetadata in $packageMetadataList) {
        Assert-NovaPackageMetadata -PackageMetadata $packageMetadata
    }

    Invoke-NovaBuild @workflowParams
    Test-NovaBuild @workflowParams

    $packagePathList = @($packageMetadataList.PackagePath)
    $packageTarget = $packagePathList -join ', '
    $packageAction = if ($packageMetadataList.Count -eq 1) {
        "Create $( $packageMetadataList[0].Type ) package from built module output"
    }
    else {
        'Create package artifacts from built module output'
    }

    if (-not $PSCmdlet.ShouldProcess($packageTarget, $packageAction)) {
        return
    }

    $packageHelper = Get-Command -Name New-NovaPackageArtifacts -CommandType Function -ErrorAction SilentlyContinue
    if ($null -ne $packageHelper) {
        return New-NovaPackageArtifacts -ProjectInfo $projectInfo -PackageMetadataList $packageMetadataList
    }

    $packagingModule = Import-Module $moduleContext.Path -Force -PassThru
    $packageCreation = {
        param($ProjectInfo, $PackageMetadataList)

        New-NovaPackageArtifacts -ProjectInfo $ProjectInfo -PackageMetadataList $PackageMetadataList
    }

    return & $packagingModule $packageCreation $projectInfo $packageMetadataList
}



