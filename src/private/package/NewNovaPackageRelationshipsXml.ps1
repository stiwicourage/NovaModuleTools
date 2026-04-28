function New-NovaPackageRelationshipsXml {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'This helper only returns XML text and does not mutate external state.')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$NuspecFileName,
        [Parameter(Mandatory)][string]$CorePropertiesPath
    )

    return @(
        '<?xml version="1.0" encoding="utf-8"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        ('  <Relationship Type="{0}" Target="/{1}" Id="RManifest" />' -f 'http://schemas.microsoft.com/packaging/2010/07/manifest', $NuspecFileName)
        ('  <Relationship Type="{0}" Target="/{1}" Id="RCoreProperties" />' -f 'http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties', $CorePropertiesPath)
        '</Relationships>'
    ) -join [Environment]::NewLine
}
