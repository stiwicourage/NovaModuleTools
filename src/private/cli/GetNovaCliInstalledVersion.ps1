function Get-NovaCliInstalledVersion {
    [CmdletBinding()]
    param(
        [object]$Module = $ExecutionContext.SessionState.Module
    )

    $installedVersion = $Module.Version.ToString()
    $prereleaseLabel = Get-NovaModulePsDataValue -Name 'Prerelease' -Module $Module

    if ( [string]::IsNullOrWhiteSpace($prereleaseLabel)) {
        return $installedVersion
    }

    return "$installedVersion-$prereleaseLabel"
}
