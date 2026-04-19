function Assert-NovaPackageMetadata {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package metadata is the established domain term validated by this helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$PackageMetadata
    )

    foreach ($requiredField in @('Id', 'Version', 'Description', 'OutputDirectory', 'PackageFileName', 'PackagePath')) {
        if ( [string]::IsNullOrWhiteSpace($PackageMetadata.$requiredField)) {
            throw "Missing package metadata value: $requiredField"
        }
    }

    if (@($PackageMetadata.Authors).Count -eq 0) {
        throw 'Missing package metadata value: Authors'
    }
}

