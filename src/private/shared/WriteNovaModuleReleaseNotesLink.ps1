function Write-NovaModuleReleaseNotesLink {
    [CmdletBinding()]
    param(
        [object]$Module = $ExecutionContext.SessionState.Module
    )

    $releaseNotesUri = Get-NovaModuleReleaseNotesUri -Module $Module
    if ($null -eq $releaseNotesUri) {
        return
    }

    Write-Host "Release notes: $releaseNotesUri"
}
