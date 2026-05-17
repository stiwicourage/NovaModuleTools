BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageArtifactType.ps1')

    . (Join-Path $PSScriptRoot 'GetNovaPackageArtifactType.TestSupport.ps1')
}

Describe 'Get-NovaPackageArtifactType' {
    It 'returns NuGet for .nupkg' {
        Get-NovaPackageArtifactType -PackagePath '/o/x.nupkg' | Should -Be 'NuGet'
    }

    It 'returns Zip for .zip' {
        Get-NovaPackageArtifactType -PackagePath '/o/x.zip' | Should -Be 'Zip'
    }

    It 'throws when extension is unknown' {
        {Get-NovaPackageArtifactType -PackagePath '/o/x.tar'} | Should -Throw '*Unsupported package file extension*'
    }

    It 'throws when no extension is present' {
        {Get-NovaPackageArtifactType -PackagePath '/o/x'} | Should -Throw '*Unsupported package file extension*'
    }
}
