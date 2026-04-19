function New-NovaPackageCorePropertiesXml {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'This helper only returns XML text and does not mutate external state.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$PackageMetadata
    )

    $creator = [System.Security.SecurityElement]::Escape((@($PackageMetadata.Authors) -join ', '))
    $description = [System.Security.SecurityElement]::Escape($PackageMetadata.Description)
    $identifier = [System.Security.SecurityElement]::Escape($PackageMetadata.Id)
    $version = [System.Security.SecurityElement]::Escape($PackageMetadata.Version)
    $keywords = [System.Security.SecurityElement]::Escape((@($PackageMetadata.Tags) -join ' '))

    return @(
        '<?xml version="1.0" encoding="utf-8"?>'
        '<coreProperties xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://schemas.openxmlformats.org/package/2006/metadata/core-properties">'
        "  <dc:creator>$creator</dc:creator>"
        "  <dc:description>$description</dc:description>"
        "  <dc:identifier>$identifier</dc:identifier>"
        "  <version>$version</version>"
        "  <keywords>$keywords</keywords>"
        '  <lastModifiedBy>NovaModuleTools</lastModifiedBy>'
        '</coreProperties>'
    ) -join [Environment]::NewLine
}

