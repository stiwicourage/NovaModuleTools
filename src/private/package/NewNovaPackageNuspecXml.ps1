function New-NovaPackageNuspecXml {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'This helper only returns XML text and does not mutate external state.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$PackageMetadata
    )

    $metadataLines = @(
        '  <metadata>'
        (Get-NovaPackageMetadataElement -Name 'id' -Value $PackageMetadata.Id)
        (Get-NovaPackageMetadataElement -Name 'version' -Value $PackageMetadata.Version)
        (Get-NovaPackageMetadataElement -Name 'authors' -Value (@($PackageMetadata.Authors) -join ', '))
        (Get-NovaPackageMetadataElement -Name 'description' -Value $PackageMetadata.Description)
        (Get-NovaPackageMetadataElement -Name 'projectUrl' -Value $PackageMetadata.ProjectUrl)
        (Get-NovaPackageMetadataElement -Name 'releaseNotes' -Value $PackageMetadata.ReleaseNotes)
        (Get-NovaPackageMetadataElement -Name 'licenseUrl' -Value $PackageMetadata.LicenseUrl)
        (Get-NovaPackageMetadataElement -Name 'tags' -Value (@($PackageMetadata.Tags) -join ' '))
        '  </metadata>'
    ) | Where-Object {$null -ne $_}

    return @(
        '<?xml version="1.0" encoding="utf-8"?>'
        '<package xmlns="http://schemas.microsoft.com/packaging/2012/06/nuspec.xsd">'
        $metadataLines
        '</package>'
    ) -join [Environment]::NewLine
}

