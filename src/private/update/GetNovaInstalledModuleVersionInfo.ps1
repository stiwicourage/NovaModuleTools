function Get-NovaInstalledModuleVersionInfo {
    [CmdletBinding()]
    param(
        [object]$Module = $ExecutionContext.SessionState.Module
    )

    $versionText = Get-NovaCliInstalledVersion -Module $Module
    $semanticVersion = [semver]$versionText

    return [pscustomobject]@{
        ModuleName = $Module.Name
        Module = $Module
        Version = $versionText
        SemanticVersion = $semanticVersion
        IsPrerelease = -not [string]::IsNullOrWhiteSpace($semanticVersion.PreReleaseLabel)
    }
}
