function Get-NovaPackageWorkflowContext {
    [CmdletBinding()]
    param(
        [pscustomobject]$ProjectInfo,
        [hashtable]$WorkflowParams = @{},
        [string]$ModulePath = $ExecutionContext.SessionState.Module.Path
    )

    $projectInfo = Get-NovaPackageWorkflowProjectInfo -ProjectInfo $ProjectInfo
    $packageMetadataList = @(Get-NovaPackageMetadataList -ProjectInfo $projectInfo)
    foreach ($packageMetadata in $packageMetadataList) {
        Assert-NovaPackageMetadata -PackageMetadata $packageMetadata
    }

    return [pscustomobject]@{
        ProjectInfo = $projectInfo
        WorkflowParams = $WorkflowParams
        PackageMetadataList = $packageMetadataList
        ModulePath = $ModulePath
        Target = Get-NovaPackageWorkflowTarget -PackageMetadataList $packageMetadataList
        Operation = Get-NovaPackageWorkflowOperation -PackageMetadataList $packageMetadataList
    }
}

function Get-NovaPackageWorkflowProjectInfo {
    [CmdletBinding()]
    param(
        [pscustomobject]$ProjectInfo
    )

    if ($null -ne $ProjectInfo) {
        return $ProjectInfo
    }

    return Get-NovaProjectInfo
}

function Get-NovaPackageWorkflowTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$PackageMetadataList
    )

    return (@($PackageMetadataList.PackagePath) -join ', ')
}

function Get-NovaPackageWorkflowOperation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$PackageMetadataList
    )

    if (@($PackageMetadataList).Count -eq 1) {
        return "Create $( $PackageMetadataList[0].Type ) package from built module output"
    }

    return 'Create package artifacts from built module output'
}
