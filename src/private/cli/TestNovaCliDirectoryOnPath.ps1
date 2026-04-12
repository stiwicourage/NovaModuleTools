function Test-NovaCliDirectoryOnPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Directory
    )

    $resolvedDirectory = [System.IO.Path]::GetFullPath($Directory)
    foreach ($entry in @($env:PATH -split [regex]::Escape([string][System.IO.Path]::PathSeparator))) {
        if ( [string]::IsNullOrWhiteSpace($entry)) {
            continue
        }

        if ([System.IO.Path]::GetFullPath($entry) -eq $resolvedDirectory) {
            return $true
        }
    }

    return $false
}

