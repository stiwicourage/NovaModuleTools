function Get-NovaPackageMetadataElement {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)][string]$Name,
        [AllowNull()][string]$Value
    )

    if ( [string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    $escapedValue = [System.Security.SecurityElement]::Escape($Value)
    return "    <$Name>$escapedValue</$Name>"
}
