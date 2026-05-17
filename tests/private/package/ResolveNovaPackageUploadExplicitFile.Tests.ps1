BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/ResolveNovaPackageUploadExplicitFile.ps1')

    . (Join-Path $PSScriptRoot 'ResolveNovaPackageUploadExplicitFile.TestSupport.ps1')
}

Describe 'Resolve-NovaPackageUploadExplicitFile' {
    BeforeEach {
        $script:file = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid().ToString() + '.nupkg')
        Set-Content -LiteralPath $script:file -Value 'x'
    }
    AfterEach {Remove-Item -LiteralPath $script:file -ErrorAction SilentlyContinue}

    It 'throws when the package file is missing' {
        Remove-Item -LiteralPath $script:file -Force
        {Resolve-NovaPackageUploadExplicitFile -PackagePath $script:file} | Should -Throw '*Package file not found*'
    }

    It 'returns file info when no type constraint is provided' {
        $info = Resolve-NovaPackageUploadExplicitFile -PackagePath $script:file -RequestedPackageTypeList @()
        $info.Type | Should -Be 'NuGet'
    }

    It 'throws when the resolved type is not in the requested type list' {
        {Resolve-NovaPackageUploadExplicitFile -PackagePath $script:file -RequestedPackageTypeList @('Zip')} | Should -Throw '*ambiguous*'
    }
}
