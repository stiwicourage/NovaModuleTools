function ConvertFrom-NovaVersionCliArgument {
    [CmdletBinding()]
    param(
        [string[]]$Arguments
    )

    $Arguments = ConvertTo-NovaCliArgumentArray -BoundParameters $PSBoundParameters -Arguments $Arguments
    if ($Arguments.Count -eq 0) {
        return @{Installed = $false}
    }

    if ($Arguments.Count -eq 1 -and $Arguments[0] -match '^(--installed|-Installed)$') {
        return @{Installed = $true}
    }

    throw "Unsupported 'nova version' usage. Use 'nova version' or 'nova version -Installed'."
}
