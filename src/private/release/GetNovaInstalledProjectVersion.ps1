function Get-NovaInstalledProjectVersion {
    [CmdletBinding()]
    param(
        [pscustomobject]$ProjectInfo = (Get-NovaProjectInfo),
        [string]$ModuleDirectoryPath
    )

    $manifestPath = Get-NovaInstalledProjectManifestPath -ProjectInfo $ProjectInfo -ModuleDirectoryPath $ModuleDirectoryPath
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        Stop-NovaOperation -Message "Local module install not found for $( $ProjectInfo.ProjectName ). Expected manifest at: $manifestPath. Run 'nova publish --local' or 'nova publish -l' first." -ErrorId 'Nova.Environment.LocalModuleInstallNotFound' -Category ObjectNotFound -TargetObject $manifestPath
    }

    $manifest = Test-ModuleManifest -Path $manifestPath -ErrorAction Stop
    return Format-NovaCliVersionString -Name $ProjectInfo.ProjectName -Version $manifest.Version.ToString()
}
