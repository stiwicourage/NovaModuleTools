BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageMetadataList.ps1')

    . (Join-Path $PSScriptRoot 'GetNovaPackageMetadataList.TestSupport.ps1')
}

Describe 'Get-NovaConfiguredPackageTypeList' {
    It 'returns configured types from a dictionary' {
        Get-NovaConfiguredPackageTypeList -PackageSettings @{Types=@('NuGet','Zip')} | Should -Be @('NuGet','Zip')
    }

    It 'returns configured types from an object' {
        Get-NovaConfiguredPackageTypeList -PackageSettings ([pscustomobject]@{Types=@('Zip')}) | Should -Be @('Zip')
    }

    It 'falls back to NuGet when none is configured' {
        Get-NovaConfiguredPackageTypeList -PackageSettings @{} | Should -Be @('NuGet')
    }
}

Describe 'Test-NovaPackageVersionIsStable' {
    It 'returns true for stable versions' {
        Test-NovaPackageVersionIsStable -Version '1.2.3' | Should -BeTrue
    }

    It 'returns false for prerelease versions' {
        Test-NovaPackageVersionIsStable -Version '1.2.3-preview01' | Should -BeFalse
    }
}

Describe 'Test-NovaPackageLatestEnabled' {
    It 'returns true when policy is always' {
        Mock ConvertTo-NovaPackageLatestPolicy {return 'always'}
        Test-NovaPackageLatestEnabled -PackageSettings @{} -Version '1.0.0-x' | Should -BeTrue
    }

    It 'returns true on stable policy with a stable version' {
        Mock ConvertTo-NovaPackageLatestPolicy {return 'stable'}
        Test-NovaPackageLatestEnabled -PackageSettings @{} -Version '1.0.0' | Should -BeTrue
    }

    It 'returns false on stable policy with prerelease version' {
        Mock ConvertTo-NovaPackageLatestPolicy {return 'stable'}
        Test-NovaPackageLatestEnabled -PackageSettings @{} -Version '1.0.0-rc' | Should -BeFalse
    }

    It 'returns false by default' {
        Mock ConvertTo-NovaPackageLatestPolicy {return 'never'}
        Test-NovaPackageLatestEnabled -PackageSettings @{} -Version '1.0.0' | Should -BeFalse
    }
}

Describe 'Get-NovaPackageMetadataList' {
    It 'emits one entry per configured type when Latest is disabled' {
        Mock ConvertTo-NovaPackageLatestPolicy {return 'never'}
        $project = [pscustomobject]@{Version='1.0.0'; Package=[pscustomobject]@{Types=@('NuGet','Zip'); Latest='never'}}
        $list = Get-NovaPackageMetadataList -ProjectInfo $project
        @($list).Count | Should -Be 2
    }

    It 'emits a latest entry per type when Latest is enabled' {
        Mock ConvertTo-NovaPackageLatestPolicy {return 'always'}
        $project = [pscustomobject]@{Version='1.0.0'; Package=[pscustomobject]@{Types=@('NuGet'); Latest='always'}}
        $list = Get-NovaPackageMetadataList -ProjectInfo $project
        @($list).Count | Should -Be 2
        @($list | Where-Object {$_.Latest}).Count | Should -Be 1
    }
}
