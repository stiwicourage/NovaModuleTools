function Get-NovaPackageWorkflowContext {
    [CmdletBinding()]
    param(
        [pscustomobject]$ProjectInfo,
        [hashtable]$WorkflowParams = @{},
        [switch]$SkipTestsRequested,
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
        SkipTestsRequested = $SkipTestsRequested.IsPresent
        PackageMetadataList = $packageMetadataList
        ModulePath = $ModulePath
        Target = Get-NovaPackageWorkflowTarget -PackageMetadataList $packageMetadataList
        Operation = Get-NovaPackageWorkflowOperation -PackageMetadataList $packageMetadataList -SkipTestsRequested:$SkipTestsRequested
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
        [Parameter(Mandatory)][object[]]$PackageMetadataList,
        [switch]$SkipTestsRequested
    )

    $validationText = if ($SkipTestsRequested) {
        'built module output with tests skipped'
    }
    else {
        'built and tested module output'
    }

    if (@($PackageMetadataList).Count -eq 1) {
        return "Create $( $PackageMetadataList[0].Type ) package from $validationText"
    }

    return "Create package artifacts from $validationText"
}
