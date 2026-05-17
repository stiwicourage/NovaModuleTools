BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageFileName.ps1')

    function ConvertTo-NovaPackageType {param($Type) if ($Type -match 'zip') {'Zip'} else {'NuGet'}}
    function Get-NovaPackageTypeExtension {param($PackageType) if ($PackageType -eq 'Zip') {'.zip'} else {'.nupkg'}}
    function Get-NovaPackageSettingValue {param($InputObject, $Name) return $InputObject.$Name}
}

Describe 'Get-NovaPackageBaseFileName' {
    It 'falls back to "PackageId.Version" when PackageFileName is blank' {
        $project = [pscustomobject]@{Package=[pscustomobject]@{PackageFileName=''}; Version='1.2.3'}
        Get-NovaPackageBaseFileName -ProjectInfo $project -PackageId 'X' | Should -Be 'X.1.2.3'
    }

    It 'strips known extensions from PackageFileName' {
        $project = [pscustomobject]@{Package=[pscustomobject]@{PackageFileName='X.nupkg'; AddVersionToFileName=$false}; Version='1.0.0'}
        Get-NovaPackageBaseFileName -ProjectInfo $project -PackageId 'X' | Should -Be 'X'
    }

    It 'appends the version when AddVersionToFileName is true' {
        $project = [pscustomobject]@{Package=[pscustomobject]@{PackageFileName='X'; AddVersionToFileName=$true}; Version='1.0.0'}
        Get-NovaPackageBaseFileName -ProjectInfo $project -PackageId 'X' | Should -Be 'X.1.0.0'
    }
}

Describe 'Add-NovaPackageVersionSuffix' {
    It 'appends the version suffix when missing' {
        Add-NovaPackageVersionSuffix -PackageFileName 'X' -Version '1.0.0' | Should -Be 'X.1.0.0'
    }

    It 'is idempotent when the suffix is already present' {
        Add-NovaPackageVersionSuffix -PackageFileName 'X.1.0.0' -Version '1.0.0' | Should -Be 'X.1.0.0'
    }
}

Describe 'ConvertTo-NovaLatestPackageFileName' {
    It 'rewrites a version suffix to .latest' {
        ConvertTo-NovaLatestPackageFileName -PackageFileName 'X.1.0.0' -Version '1.0.0' | Should -Be 'X.latest'
    }

    It 'appends .latest when no version suffix exists' {
        ConvertTo-NovaLatestPackageFileName -PackageFileName 'X' -Version '1.0.0' | Should -Be 'X.latest'
    }

    It 'is idempotent when .latest is already present' {
        ConvertTo-NovaLatestPackageFileName -PackageFileName 'X.latest' -Version '1.0.0' | Should -Be 'X.latest'
    }
}

Describe 'Get-NovaPackageFileName' {
    It 'returns "PackageId.Version.nupkg" for a default NuGet package' {
        $project = [pscustomobject]@{Package=[pscustomobject]@{PackageFileName=''}; Version='1.2.3'}
        Get-NovaPackageFileName -ProjectInfo $project -PackageId 'X' -PackageType 'NuGet' | Should -Be 'X.1.2.3.nupkg'
    }

    It 'returns the latest file name when -Latest is set' {
        $project = [pscustomobject]@{Package=[pscustomobject]@{PackageFileName=''}; Version='1.2.3'}
        Get-NovaPackageFileName -ProjectInfo $project -PackageId 'X' -PackageType 'NuGet' -Latest | Should -Be 'X.latest.nupkg'
    }
}
