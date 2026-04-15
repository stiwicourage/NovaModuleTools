function Write-NovaLocalPublishCompletionMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][bool]$ShouldRun,
        [Parameter(Mandatory)][pscustomobject]$PublishInvocation
    )

    if (-not $ShouldRun -or -not $PublishInvocation.IsLocal) {
        return
    }

    Write-Verbose 'Module copy to local path complete, Refresh session or import module manually'
}

