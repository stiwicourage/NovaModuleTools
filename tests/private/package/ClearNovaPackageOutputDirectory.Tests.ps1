BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/ClearNovaPackageOutputDirectory.ps1')

    function Assert-NovaPackageOutputDirectoryCanBeCleared {param($ProjectInfo, $OutputDirectory)}
}

Describe 'Clear-NovaPackageOutputDirectory' {
    It 'removes the existing output directory' {
        $dir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $dir | Out-Null
        Set-Content -LiteralPath (Join-Path $dir 'a.txt') -Value 'x'
        try {
            Clear-NovaPackageOutputDirectory -ProjectInfo ([pscustomobject]@{}) -OutputDirectory $dir
            Test-Path -LiteralPath $dir | Should -BeFalse
        } finally {Remove-Item -LiteralPath $dir -Recurse -Force -ErrorAction SilentlyContinue}
    }

    It 'returns silently when the directory does not exist' {
        $dir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        {Clear-NovaPackageOutputDirectory -ProjectInfo ([pscustomobject]@{}) -OutputDirectory $dir} | Should -Not -Throw
    }
}
