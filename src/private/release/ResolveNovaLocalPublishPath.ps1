function Resolve-NovaLocalPublishPath {
    [CmdletBinding()]
    param(
        [string]$ModuleDirectoryPath
    )

    if ( [string]::IsNullOrWhiteSpace($ModuleDirectoryPath)) {
        return Get-LocalModulePath
    }

    return $ModuleDirectoryPath
}

