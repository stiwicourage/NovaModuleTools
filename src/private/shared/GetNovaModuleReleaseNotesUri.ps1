function Get-NovaModuleReleaseNotesUri {
    [CmdletBinding()]
    param(
        [object]$Module = $ExecutionContext.SessionState.Module
    )

    $releaseNotesUri = Get-NovaModulePsDataValue -Name 'ReleaseNotes' -Module $Module
    if ( [string]::IsNullOrWhiteSpace($releaseNotesUri)) {
        return $null
    }

    return $releaseNotesUri.Trim()
}
