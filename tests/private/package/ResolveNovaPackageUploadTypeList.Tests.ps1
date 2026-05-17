BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/ResolveNovaPackageUploadTypeList.ps1')

    . (Join-Path $PSScriptRoot 'ResolveNovaPackageUploadTypeList.TestSupport.ps1')
}

Describe 'Resolve-NovaRequestedPackageUploadTypeList' {
    It 'returns deduplicated requested types when no explicit pattern type is set' {
        $patternInfo = [pscustomobject]@{Pattern='X*'; ExplicitPackageType=$null}
        $list = Resolve-NovaRequestedPackageUploadTypeList -RequestedTypeList @('NuGet','NuGet','Zip') -PatternInfo $patternInfo
        @($list).Count | Should -Be 2
    }

    It 'returns only the matching type when the pattern is explicit' {
        $patternInfo = [pscustomobject]@{Pattern='X*.zip'; ExplicitPackageType='Zip'}
        $list = Resolve-NovaRequestedPackageUploadTypeList -RequestedTypeList @('Zip','NuGet') -PatternInfo $patternInfo
        $list | Should -Be @('Zip')
    }

    It 'throws when no requested type matches the explicit pattern type' {
        $patternInfo = [pscustomobject]@{Pattern='X*.zip'; ExplicitPackageType='Zip'}
        {Resolve-NovaRequestedPackageUploadTypeList -RequestedTypeList @('NuGet') -PatternInfo $patternInfo} | Should -Throw '*FileNamePattern*' -Because 'no requested type matches the explicit type'
    }
}

Describe 'Resolve-NovaPackageUploadTypeList' {
    It 'uses requested types when provided' {
        Resolve-NovaPackageUploadTypeList -ProjectInfo ([pscustomobject]@{}) -PackageType @('NuGet') | Should -Be @('NuGet')
    }

    It 'returns the explicit pattern type when no request and pattern is explicit' {
        Mock Get-NovaPackageArtifactPatternInfo {return [pscustomobject]@{Pattern='x.zip'; ExplicitPackageType='Zip'}}
        Resolve-NovaPackageUploadTypeList -ProjectInfo ([pscustomobject]@{}) | Should -Be @('Zip')
    }

    It 'falls back to configured metadata types when no request and no explicit pattern' {
        $list = Resolve-NovaPackageUploadTypeList -ProjectInfo ([pscustomobject]@{})
        @($list).Count | Should -Be 2
    }
}
