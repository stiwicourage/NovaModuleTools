function Resolve-NovaLocalPublishPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [string]$ModuleDirectoryPath
    )

    if ( [string]::IsNullOrWhiteSpace($ModuleDirectoryPath)) {
        return Get-LocalModulePath
    }

    return $ModuleDirectoryPath
}
