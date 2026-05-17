BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/ConvertToNovaPackageType.ps1')

    function Stop-NovaOperation {param([string]$Message, [string]$ErrorId, $Category, $TargetObject)
        throw $Message
    }
}

Describe 'ConvertTo-NovaPackageType' {
    It 'returns NuGet for nuget alias' {
        ConvertTo-NovaPackageType -Type 'nuget' | Should -Be 'NuGet'
    }

    It 'returns NuGet for .nupkg extension' {
        ConvertTo-NovaPackageType -Type '.nupkg' | Should -Be 'NuGet'
    }

    It 'returns Zip for zip alias' {
        ConvertTo-NovaPackageType -Type 'zip' | Should -Be 'Zip'
    }

    It 'returns Zip for .zip extension' {
        ConvertTo-NovaPackageType -Type '.zip' | Should -Be 'Zip'
    }

    It 'is case-insensitive' {
        ConvertTo-NovaPackageType -Type 'NUGET' | Should -Be 'NuGet'
    }

    It 'throws for unsupported values' {
        {ConvertTo-NovaPackageType -Type 'tarball'} | Should -Throw
    }
}
