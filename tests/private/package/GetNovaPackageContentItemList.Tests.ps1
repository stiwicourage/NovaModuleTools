BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageContentItemList.ps1')

    function Stop-NovaOperation {param($Message, $ErrorId, $Category, $TargetObject) throw $Message}
    function Get-NormalizedRelativePath {param($Root, $FullName) return [System.IO.Path]::GetFileName($FullName)}
}

Describe 'Get-NovaPackageContentItemList' {
    BeforeEach {
        $script:dir = Join-Path ([System.IO.Path]::GetTempPath()) ([guid]::NewGuid())
        New-Item -ItemType Directory -Path $script:dir | Out-Null
        $script:project = [pscustomobject]@{OutputModuleDir=$script:dir}
        $script:meta = [pscustomobject]@{ContentRoot='content/X'}
    }
    AfterEach {
        Remove-Item -LiteralPath $script:dir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It 'throws when the output dir does not exist' {
        $missing = [pscustomobject]@{OutputModuleDir='/does/not/exist/abc'}
        {Get-NovaPackageContentItemList -ProjectInfo $missing -PackageMetadata $script:meta} | Should -Throw '*Built module output not found*'
    }

    It 'throws when the output dir has no files' {
        {Get-NovaPackageContentItemList -ProjectInfo $script:project -PackageMetadata $script:meta} | Should -Throw '*no files*'
    }

    It 'returns SourcePath and PackagePath entries for each file' {
        Set-Content -LiteralPath (Join-Path $script:dir 'a.txt') -Value 'x'
        $result = Get-NovaPackageContentItemList -ProjectInfo $script:project -PackageMetadata $script:meta
        @($result).Count | Should -Be 1
        $result[0].PackagePath | Should -Be 'content/X/a.txt'
    }
}
