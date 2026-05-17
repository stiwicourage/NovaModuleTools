BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageTypeExtension.ps1')

    function ConvertTo-NovaPackageType {param($Type) if ($Type -eq 'Zip') {'Zip'} else {'NuGet'}}
}

Describe 'Get-NovaPackageTypeExtension' {
    It 'returns .zip for Zip' {
        Get-NovaPackageTypeExtension -PackageType 'Zip' | Should -Be '.zip'
    }

    It 'returns .nupkg for NuGet' {
        Get-NovaPackageTypeExtension -PackageType 'NuGet' | Should -Be '.nupkg'
    }
}
