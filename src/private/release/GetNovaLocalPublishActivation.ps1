function Get-NovaLocalPublishActivation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$PublishInvocation
    )

    if (-not $PublishInvocation.IsLocal) {
        return $null
    }

    return [pscustomobject]@{
        ManifestPath = $null
        ImportAction = (Get-Command -Name Import-NovaPublishedLocalModule -CommandType Function).ScriptBlock
    }
}
