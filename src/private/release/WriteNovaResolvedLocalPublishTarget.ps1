function Write-NovaResolvedLocalPublishTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$PublishInvocation
    )

    if (-not $PublishInvocation.IsLocal) {
        return
    }

    Write-Verbose "Using $( $PublishInvocation.Target ) as path"
}

