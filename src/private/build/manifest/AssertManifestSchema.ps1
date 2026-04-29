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

    Stop-NovaOperation -Message "Unknown parameter(s) in Manifest: $( $unknownParameter -join ', ' )" -ErrorId 'Nova.Configuration.ManifestUnknownParameter' -Category InvalidData -TargetObject $unknownParameter
}
