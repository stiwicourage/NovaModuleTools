function Get-NovaPublishedLocalManifestPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$PublishInvocation
    )

    if (-not $PublishInvocation.IsLocal) {
        return $null
    }

    $projectInfo = $PublishInvocation.Parameters.ProjectInfo
    $moduleDirectory = Join-Path -Path $PublishInvocation.Target -ChildPath $projectInfo.ProjectName
    return Join-Path -Path $moduleDirectory -ChildPath "$( $projectInfo.ProjectName ).psd1"
}
