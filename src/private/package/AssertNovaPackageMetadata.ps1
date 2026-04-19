function Assert-NovaPackageMetadata {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package metadata is the established domain term validated by this helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$PackageMetadata
    )

    if (-not $PackageMetadata.Enabled) {
        throw 'Package.Enabled is false in project.json. Enable packaging before running Pack-NovaModule.'
    }

    foreach ($requiredField in @('Id', 'Version', 'Description', 'PackagePath')) {
        if ( [string]::IsNullOrWhiteSpace($PackageMetadata.$requiredField)) {
            throw "Missing package metadata value: $requiredField"
        }
    }

    if (@($PackageMetadata.Authors).Count -eq 0) {
        throw 'Missing package metadata value: Authors'
    }
}

