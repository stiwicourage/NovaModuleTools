BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageMetadata.ps1')

    function ConvertTo-NovaPackageType {param($Type) if ($Type -match '(?i)zip') {'Zip'} else {'NuGet'}}
    function Get-NovaPackageAuthorList {param($AuthorValue) return @($AuthorValue)}
    function Get-NovaManifestValue {param($Manifest, $Name) return $Manifest.$Name}
    function Get-NovaPackageFileName {param($ProjectInfo, $PackageId, $PackageType, [switch]$Latest)
        $base = "$PackageId.$($ProjectInfo.Version)"
        if ($Latest) {$base = "$PackageId.latest"}
        return "$base$( if ($PackageType -eq 'Zip') {'.zip'} else {'.nupkg'} )"
    }
    function Get-NovaPackageOutputDirectory {param($ProjectInfo) return '/output'}
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
}
