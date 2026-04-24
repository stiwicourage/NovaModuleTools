function Get-NovaPackageContentItemList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][pscustomobject]$PackageMetadata
    )

    if (-not (Test-Path -LiteralPath $ProjectInfo.OutputModuleDir)) {
        Stop-NovaOperation -Message "Built module output not found: $( $ProjectInfo.OutputModuleDir ). Run Invoke-NovaBuild before packaging." -ErrorId 'Nova.Environment.PackageBuildOutputNotFound' -Category ObjectNotFound -TargetObject $ProjectInfo.OutputModuleDir
    }

    $sourceFiles = @(Get-ChildItem -LiteralPath $ProjectInfo.OutputModuleDir -File -Recurse | Sort-Object FullName)
    if ($sourceFiles.Count -eq 0) {
        Stop-NovaOperation -Message "Built module output has no files to package: $( $ProjectInfo.OutputModuleDir )" -ErrorId 'Nova.Workflow.PackageBuildOutputEmpty' -Category InvalidOperation -TargetObject $ProjectInfo.OutputModuleDir
    }

    return @(
    $sourceFiles | ForEach-Object {
        $relativePath = Get-NormalizedRelativePath -Root $ProjectInfo.OutputModuleDir -FullName $_.FullName
        [pscustomobject]@{
            SourcePath = $_.FullName
            PackagePath = "$( $PackageMetadata.ContentRoot )/$relativePath"
        }
    }
    )
}

