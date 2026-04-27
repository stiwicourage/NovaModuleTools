function Get-NovaModuleReleaseNotesMessage {
    [CmdletBinding(DefaultParameterSetName = 'Module')]
    param(
        [Parameter(ParameterSetName = 'Module')]
        [object]$Module = $ExecutionContext.SessionState.Module,
        [Parameter(ParameterSetName = 'Uri')]
        [AllowNull()][string]$ReleaseNotesUri
    )

    if ($PSCmdlet.ParameterSetName -eq 'Module') {
        $ReleaseNotesUri = Get-NovaModuleReleaseNotesUri -Module $Module
    }

    if ( [string]::IsNullOrWhiteSpace($ReleaseNotesUri)) {
        return $null
    }

    return "Release notes: $($ReleaseNotesUri.Trim() )"
}

function Write-NovaModuleReleaseNotesLink {
    [CmdletBinding(DefaultParameterSetName = 'Module')]
    param(
        [Parameter(ParameterSetName = 'Module')]
        [object]$Module = $ExecutionContext.SessionState.Module,
        [Parameter(ParameterSetName = 'Uri')]
        [AllowNull()][string]$ReleaseNotesUri
    )

    $message = Get-NovaModuleReleaseNotesMessage @PSBoundParameters
    if ($null -eq $message) {
        return
    }

    Write-Host $message
}
