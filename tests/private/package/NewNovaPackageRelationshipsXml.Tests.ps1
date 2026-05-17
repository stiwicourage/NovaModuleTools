BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/NewNovaPackageRelationshipsXml.ps1')
}

Describe 'New-NovaPackageRelationshipsXml' {
    It 'emits the manifest and core-properties relationships referencing the supplied paths' {
        $xml = New-NovaPackageRelationshipsXml -NuspecFileName 'X.nuspec' -CorePropertiesPath 'package/services/metadata/core-properties/abc.psmdcp'
        $xml | Should -Match 'Target="/X.nuspec"'
        $xml | Should -Match 'Target="/package/services/metadata/core-properties/abc.psmdcp"'
        $xml | Should -Match 'Id="RManifest"'
        $xml | Should -Match 'Id="RCoreProperties"'
    }
}
