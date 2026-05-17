BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/NewNovaPackageArtifact.ps1')

    function Assert-NovaPackageMetadata {param($PackageMetadata)}
    function Initialize-NovaPackageOutputDirectory {param($ProjectInfo, $PackageMetadata)}
    function New-NovaNuGetPackageArtifact {param($ProjectInfo, $PackageMetadata) $script:nugetCalled = $true}
    function New-NovaZipPackageArtifact {param($ProjectInfo, $PackageMetadata) $script:zipCalled = $true}
    function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
}

Describe 'New-NovaPackageArtifact' {
    BeforeEach {
        $script:project = [pscustomobject]@{OutputModuleDir='/dist/x'}
        $script:meta = [pscustomobject]@{Type='NuGet'; Latest=$false; Id='X'; Version='1.0.0'; PackageFileName='X.1.0.0.nupkg'; PackagePath='/o/X.1.0.0.nupkg'; OutputDirectory='/o'}
    }

    It 'dispatches to NuGet creator for NuGet packages' {
        $script:nugetCalled = $false
        $result = New-NovaPackageArtifact -ProjectInfo $script:project -PackageMetadata $script:meta -OutputDirectoryReady
        $script:nugetCalled | Should -BeTrue
        $result.Type | Should -Be 'NuGet'
        $result.SourceModuleDirectory | Should -Be '/dist/x'
    }

    It 'dispatches to Zip creator for Zip packages' {
        $script:zipCalled = $false
        $script:meta.Type = 'Zip'
        New-NovaPackageArtifact -ProjectInfo $script:project -PackageMetadata $script:meta -OutputDirectoryReady | Out-Null
        $script:zipCalled | Should -BeTrue
    }

    It 'throws when the package type is unsupported' {
        $script:meta.Type = 'Tar'
        {New-NovaPackageArtifact -ProjectInfo $script:project -PackageMetadata $script:meta -OutputDirectoryReady} | Should -Throw '*Unsupported package type*'
    }

    It 'initializes the output directory when OutputDirectoryReady is not set' {
        Mock Initialize-NovaPackageOutputDirectory {}
        New-NovaPackageArtifact -ProjectInfo $script:project -PackageMetadata $script:meta | Out-Null
        Should -Invoke Initialize-NovaPackageOutputDirectory -Times 1
    }
}
