function Get-NovaPublishedLocalManifestPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$PublishInvocation
    )

    if (-not $PublishInvocation.IsLocal) {
        return $null
    }

    $projectInfo = $PublishInvocation.Parameters.ProjectInfo
    $versionDirectory = Get-NovaLocalPublishVersionDirectory -ProjectInfo $projectInfo -ModuleDirectoryPath $PublishInvocation.Target
    return Join-Path -Path $versionDirectory -ChildPath "$( $projectInfo.ProjectName ).psd1"
}
