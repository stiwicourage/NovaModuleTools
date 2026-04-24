function Assert-NovaPackageMetadata {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseSingularNouns', '', Justification = 'Package metadata is the established domain term validated by this helper.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$PackageMetadata
    )

    foreach ($requiredField in @('Type', 'Id', 'Version', 'Description', 'OutputDirectory', 'PackageFileName', 'PackagePath')) {
        if ( [string]::IsNullOrWhiteSpace($PackageMetadata.$requiredField)) {
            Stop-NovaOperation -Message "Missing package metadata value: $requiredField" -ErrorId 'Nova.Configuration.PackageMetadataValueMissing' -Category InvalidData -TargetObject $requiredField
        }
    }

    if (@($PackageMetadata.Authors).Count -eq 0) {
        Stop-NovaOperation -Message 'Missing package metadata value: Authors' -ErrorId 'Nova.Configuration.PackageMetadataValueMissing' -Category InvalidData -TargetObject 'Authors'
    }
}

