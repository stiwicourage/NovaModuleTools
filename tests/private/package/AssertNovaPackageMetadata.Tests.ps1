BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/AssertNovaPackageMetadata.ps1')

    function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
}

Describe 'Assert-NovaPackageMetadata' {
    It 'returns silently when all required fields are present' {
        $meta = [pscustomobject]@{Type='NuGet'; Id='X'; Version='1.0.0'; Description='d'; OutputDirectory='/o'; PackageFileName='X.nupkg'; PackagePath='/o/X.nupkg'; Authors=@('a')}
        {Assert-NovaPackageMetadata -PackageMetadata $meta} | Should -Not -Throw
    }

    It 'throws when a required field is missing' {
        $meta = [pscustomobject]@{Type='NuGet'; Id=''; Version='1.0.0'; Description='d'; OutputDirectory='/o'; PackageFileName='X.nupkg'; PackagePath='/o/X.nupkg'; Authors=@('a')}
        {Assert-NovaPackageMetadata -PackageMetadata $meta} | Should -Throw '*Id*'
    }

    It 'throws when Authors is empty' {
        $meta = [pscustomobject]@{Type='NuGet'; Id='X'; Version='1.0.0'; Description='d'; OutputDirectory='/o'; PackageFileName='X.nupkg'; PackagePath='/o/X.nupkg'; Authors=@()}
        {Assert-NovaPackageMetadata -PackageMetadata $meta} | Should -Throw '*Authors*'
    }
}
