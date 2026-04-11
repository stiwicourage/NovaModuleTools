function Assert-ManifestSchema {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][hashtable]$Manifest,
        [Parameter(Mandatory)][string[]]$AllowedParameter
    )

    $unknownParameter = @(
    $Manifest.Keys |
            Where-Object {$AllowedParameter -notcontains $_} |
            Sort-Object
    )

    if ($unknownParameter.Count -eq 0) {
        return
    }

    throw "Unknown parameter(s) in Manifest: $( $unknownParameter -join ', ' )"
}
