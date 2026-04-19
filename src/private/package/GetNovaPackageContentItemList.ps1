function Get-NovaPackageContentItemList {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][pscustomobject]$PackageMetadata
    )

    if (-not (Test-Path -LiteralPath $ProjectInfo.OutputModuleDir)) {
        throw "Built module output not found: $( $ProjectInfo.OutputModuleDir ). Run Invoke-NovaBuild before packaging."
    }

    $sourceFiles = @(Get-ChildItem -LiteralPath $ProjectInfo.OutputModuleDir -File -Recurse | Sort-Object FullName)
    if ($sourceFiles.Count -eq 0) {
        throw "Built module output has no files to package: $( $ProjectInfo.OutputModuleDir )"
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

