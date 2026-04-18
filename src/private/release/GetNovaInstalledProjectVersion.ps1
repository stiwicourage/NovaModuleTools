function Get-NovaInstalledProjectVersion {
    [CmdletBinding()]
    param(
        [pscustomobject]$ProjectInfo = (Get-NovaProjectInfo),
        [string]$ModuleDirectoryPath
    )

    $manifestPath = Get-NovaInstalledProjectManifestPath -ProjectInfo $ProjectInfo -ModuleDirectoryPath $ModuleDirectoryPath
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Local module install not found for $( $ProjectInfo.ProjectName ). Expected manifest at: $manifestPath. Run 'nova publish -local' first."
    }

    $manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
    return Format-NovaCliVersionString -Name $ProjectInfo.ProjectName -Version $manifest.Version.ToString()
}

