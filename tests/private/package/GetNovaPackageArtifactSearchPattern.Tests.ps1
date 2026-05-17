BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageArtifactSearchPattern.ps1')

    function Get-NovaPackageArtifactPatternInfo {param($ProjectInfo) return [pscustomobject]@{Pattern='X*'; ExplicitPackageType=$null}}
    function Get-NovaPackageTypeExtension {param($PackageType) return '.nupkg'}
}

Describe 'Get-NovaPackageArtifactSearchPattern' {
    It 'returns the explicit pattern unchanged when ExplicitPackageType is set' {
        Mock Get-NovaPackageArtifactPatternInfo {return [pscustomobject]@{Pattern='X*.zip'; ExplicitPackageType='Zip'}}
        Get-NovaPackageArtifactSearchPattern -ProjectInfo ([pscustomobject]@{}) -PackageType 'Zip' | Should -Be 'X*.zip'
    }

    It 'appends the type extension when no explicit type is configured' {
        Get-NovaPackageArtifactSearchPattern -ProjectInfo ([pscustomobject]@{}) -PackageType 'NuGet' | Should -Be 'X*.nupkg'
    }
}
