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
        Stop-NovaOperation -Message 'HOME environment variable is not set. Provide -DestinationDirectory explicitly.' -ErrorId 'Nova.Environment.HomeDirectoryMissing' -Category ResourceUnavailable -TargetObject 'HOME'
    }

    return [System.IO.Path]::Join($homeDirectory, '.local', 'bin')
}
