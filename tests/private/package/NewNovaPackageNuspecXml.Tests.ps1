BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/NewNovaPackageNuspecXml.ps1')

    function Get-NovaPackageMetadataElement {param($Name, $Value)
        if ([string]::IsNullOrWhiteSpace($Value)) {return $null}
        return "    <$Name>$Value</$Name>"
    }
}

Describe 'New-NovaPackageNuspecXml' {
    It 'emits id, version, authors, description, and tags elements' {
        $meta = [pscustomobject]@{Id='X'; Version='1.0.0'; Authors=@('alice'); Description='d'; ProjectUrl=''; ReleaseNotes=''; LicenseUrl=''; Tags=@('t')}
        $xml = New-NovaPackageNuspecXml -PackageMetadata $meta
        $xml | Should -Match '<id>X</id>'
        $xml | Should -Match '<version>1.0.0</version>'
        $xml | Should -Match '<authors>alice</authors>'
        $xml | Should -Match '<tags>t</tags>'
        $xml | Should -Not -Match 'projectUrl'
    }
}
