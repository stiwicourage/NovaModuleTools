function Get-NovaLocalPublishVersionDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$ProjectInfo,
        [Parameter(Mandatory)][string]$ModuleDirectoryPath
    )

    $manifestPath = Get-NovaBuiltModuleManifestPathForCi -ProjectInfo $ProjectInfo
    $manifest = Import-PowerShellDataFile -LiteralPath $manifestPath -ErrorAction Stop
    $version = $null
    if (-not [version]::TryParse([string]$manifest['ModuleVersion'], [ref]$version)) {
        throw "Built module manifest '$manifestPath' must contain a numeric ModuleVersion."
    }

    $moduleDirectory = Join-Path -Path $ModuleDirectoryPath -ChildPath $ProjectInfo.ProjectName
    return Join-Path -Path $moduleDirectory -ChildPath $version.ToString()
}
