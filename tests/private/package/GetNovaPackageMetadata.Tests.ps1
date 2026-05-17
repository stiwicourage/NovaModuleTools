BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageMetadata.ps1')

    . (Join-Path $PSScriptRoot 'GetNovaPackageMetadata.TestSupport.ps1')
}

Describe 'Get-NovaPackageMetadata' {
    BeforeEach {
        $script:project = [pscustomobject]@{
            ProjectName='Sample'
            Version='1.2.3'
            Manifest=[pscustomobject]@{Tags=@('a','b'); ProjectUri='u'; ReleaseNotes='r'; LicenseUri='l'}
            Package=[pscustomobject]@{Id='X'; Authors='alice'; Description='d'; Types=@('NuGet'); OutputDirectory=[pscustomobject]@{Clean=$true}}
        }
    }

    It 'returns NuGet metadata defaulting to content/Sample root' {
        $meta = Get-NovaPackageMetadata -ProjectInfo $script:project
        $meta.Type | Should -Be 'NuGet'
        $meta.Id | Should -Be 'X'
        $meta.Version | Should -Be '1.2.3'
        $meta.ContentRoot | Should -Be 'content/Sample'
        $meta.Latest | Should -BeFalse
        $meta.CleanOutputDirectory | Should -BeTrue
    }

    It 'uses Sample (no "content/" prefix) as ContentRoot for Zip packages' {
        $script:project.Package.Types = @('Zip')
        $meta = Get-NovaPackageMetadata -ProjectInfo $script:project -PackageType 'Zip'
        $meta.Type | Should -Be 'Zip'
        $meta.ContentRoot | Should -Be 'Sample'
    }

    It 'returns Latest=true when -Latest is set' {
        $meta = Get-NovaPackageMetadata -ProjectInfo $script:project -Latest
        $meta.Latest | Should -BeTrue
        $meta.PackageFileName | Should -Match '\.latest\.'
    }

    It 'reads Types from a hashtable-style Package settings' {
        $script:project.Package = @{Id='X'; Authors='alice'; Description='d'; Types=@('Zip'); OutputDirectory=@{Clean=$false}}
        $meta = Get-NovaPackageMetadata -ProjectInfo $script:project
        $meta.Type | Should -Be 'Zip'
    }

    It 'defaults to NuGet when no Types are configured and no explicit PackageType' {
        $script:project.Package.Types = @()
        $meta = Get-NovaPackageMetadata -ProjectInfo $script:project
        $meta.Type | Should -Be 'NuGet'
    }
}
