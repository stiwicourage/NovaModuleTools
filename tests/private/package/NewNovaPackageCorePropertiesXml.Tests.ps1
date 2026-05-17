BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/NewNovaPackageCorePropertiesXml.ps1')
}

Describe 'New-NovaPackageCorePropertiesXml' {
    It 'escapes XML-significant characters in metadata' {
        $meta = [pscustomobject]@{Authors=@('A & B'); Description='d'; Id='X'; Version='1.0.0'; Tags=@('t1','t2')}
        $xml = New-NovaPackageCorePropertiesXml -PackageMetadata $meta
        $xml | Should -Match '<dc:creator>A &amp; B</dc:creator>'
        $xml | Should -Match '<keywords>t1 t2</keywords>'
        $xml | Should -Match '<lastModifiedBy>NovaModuleTools</lastModifiedBy>'
    }
}
