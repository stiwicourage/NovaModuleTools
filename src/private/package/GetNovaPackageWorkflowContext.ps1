function Get-NovaPackageWorkflowContext {
    [CmdletBinding()]
    param(
        [pscustomobject]$ProjectInfo,
        [hashtable]$WorkflowParams = @{},
        [switch]$SkipTestsRequested,
        [switch]$OverrideWarningRequested
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
        OverrideWarningRequested = $OverrideWarningRequested.IsPresent
        PackageMetadataList = $packageMetadataList
        ModulePath = Get-NovaPackageWorkflowModulePath
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

function Get-NovaPackageWorkflowModulePath {
    [CmdletBinding()]
    param()

    return $ExecutionContext.SessionState.Module.Path
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
