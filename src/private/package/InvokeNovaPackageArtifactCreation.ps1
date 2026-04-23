function Invoke-NovaPackageArtifactCreation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    $projectInfo = $WorkflowContext.ProjectInfo
    $packageMetadataList = $WorkflowContext.PackageMetadataList
    $modulePath = $WorkflowContext.ModulePath

    $packageHelper = Get-Command -Name New-NovaPackageArtifacts -CommandType Function -ErrorAction SilentlyContinue
    if ($null -ne $packageHelper) {
        return New-NovaPackageArtifacts -ProjectInfo $projectInfo -PackageMetadataList $packageMetadataList
    }

    $packagingModule = Import-Module $modulePath -Force -PassThru
    $packageCreation = {
        param($ProjectInfo, $PackageMetadataList)

        New-NovaPackageArtifacts -ProjectInfo $ProjectInfo -PackageMetadataList $PackageMetadataList
    }

    return & $packagingModule $packageCreation $projectInfo $packageMetadataList
}
