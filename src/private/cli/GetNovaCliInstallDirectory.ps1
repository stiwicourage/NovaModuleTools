function Get-NovaCliInstallDirectory {
    [CmdletBinding()]
    param(
        [string]$DestinationDirectory
    )

    if (-not [string]::IsNullOrWhiteSpace($DestinationDirectory)) {
        return [System.IO.Path]::GetFullPath($DestinationDirectory)
    }

    if ( [string]::IsNullOrWhiteSpace($HOME)) {
        throw 'HOME environment variable is not set. Provide -DestinationDirectory explicitly.'
    }

    return [System.IO.Path]::Join($HOME, '.local', 'bin')
}

