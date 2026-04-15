function Get-NovaCliInstallDirectory {
    [CmdletBinding()]
    param(
        [string]$DestinationDirectory
    )

    if (-not [string]::IsNullOrWhiteSpace($DestinationDirectory)) {
        return [System.IO.Path]::GetFullPath($DestinationDirectory)
    }

    $homeDirectory = $env:HOME

    if ( [string]::IsNullOrWhiteSpace($homeDirectory)) {
        throw 'HOME environment variable is not set. Provide -DestinationDirectory explicitly.'
    }

    return [System.IO.Path]::Join($homeDirectory, '.local', 'bin')
}

