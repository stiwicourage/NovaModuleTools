BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/NewNovaPackageContentTypesXml.ps1')
}

Describe 'New-NovaPackageContentTypesXml' {
    It 'emits default Default extensions in the XML document' {
        $entries = @([pscustomobject]@{PackagePath='content/x/a.txt'})
        $xml = New-NovaPackageContentTypesXml -FileEntries $entries
        $xml | Should -Match '<Types '
        $xml | Should -Match 'Extension="rels"'
        $xml | Should -Match 'Extension="psmdcp"'
        $xml | Should -Match 'Extension="txt"'
    }

    It 'emits Override entries for files without extensions' {
        $entries = @([pscustomobject]@{PackagePath='content/x/NOTICE'})
        $xml = New-NovaPackageContentTypesXml -FileEntries $entries
        $xml | Should -Match '<Override PartName="/content/x/NOTICE"'
    }
}
