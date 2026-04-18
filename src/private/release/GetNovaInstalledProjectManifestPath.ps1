function Get-NovaInstalledProjectManifestPath {
    [CmdletBinding()]
    param(
        [pscustomobject]$ProjectInfo = (Get-NovaProjectInfo),
        [string]$ModuleDirectoryPath
    )

    $publishInvocation = [pscustomobject]@{
        IsLocal = $true
        Target = Resolve-NovaLocalPublishPath -ModuleDirectoryPath $ModuleDirectoryPath
        Parameters = @{ProjectInfo = $ProjectInfo}
    }

    return Get-NovaPublishedLocalManifestPath -PublishInvocation $publishInvocation
}
