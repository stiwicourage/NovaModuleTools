BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/InitializeNovaPackageOutputDirectory.ps1')

    . (Join-Path $PSScriptRoot 'InitializeNovaPackageOutputDirectory.TestSupport.ps1')
}

Describe 'Initialize-NovaPackageOutputDirectory' {
    BeforeEach {
        $script:dir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
    }
    AfterEach {
        Remove-Item -LiteralPath $script:dir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'creates the output directory when it does not exist' {
        $meta = [pscustomobject]@{CleanOutputDirectory=$false; OutputDirectory=$script:dir}
        Initialize-NovaPackageOutputDirectory -ProjectInfo ([pscustomobject]@{}) -PackageMetadataList @($meta)
        Test-Path -LiteralPath $script:dir | Should -BeTrue
    }

    It 'calls Clear-NovaPackageOutputDirectory when CleanOutputDirectory is true' {
        $meta = [pscustomobject]@{CleanOutputDirectory=$true; OutputDirectory=$script:dir}
        Mock Clear-NovaPackageOutputDirectory {}
        Initialize-NovaPackageOutputDirectory -ProjectInfo ([pscustomobject]@{}) -PackageMetadataList @($meta)
        Should -Invoke Clear-NovaPackageOutputDirectory -Times 1
    }

    It 'throws when PackageMetadataList is empty' {
        {Initialize-NovaPackageOutputDirectory -ProjectInfo ([pscustomobject]@{}) -PackageMetadataList @()} | Should -Throw '*cannot be empty*'
    }
}
