BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/shared/GetNovaResolvedProjectPackageTypeList.ps1')

    function ConvertTo-NovaPackageType {
        param([string]$Type)
        switch ($Type.ToLowerInvariant()) {
            'nuget' {return 'NuGet'}
            'zip' {return 'Zip'}
            default {throw "unsupported $Type"}
        }
    }
}

Describe 'Get-NovaResolvedProjectPackageTypeList' {
    It 'returns the default NuGet when no Types are configured' {
        $result = Get-NovaResolvedProjectPackageTypeList -PackageSettings ([ordered]@{})

        $result | Should -Be @('NuGet')
    }

    It 'resolves and deduplicates the configured Types' {
        $result = Get-NovaResolvedProjectPackageTypeList -PackageSettings ([ordered]@{Types = @('nuget', 'zip', 'nuget')})

        $result.Count | Should -Be 2
        $result[0] | Should -Be 'NuGet'
        $result[1] | Should -Be 'Zip'
    }

    It 'skips whitespace entries' {
        $result = Get-NovaResolvedProjectPackageTypeList -PackageSettings ([ordered]@{Types = @('', '  ', 'zip')})

        $result | Should -Be @('Zip')
    }

    It 'returns the default NuGet when Types is configured but empty' {
        $result = Get-NovaResolvedProjectPackageTypeList -PackageSettings ([ordered]@{Types = @()})

        $result | Should -Be @('NuGet')
    }
}
