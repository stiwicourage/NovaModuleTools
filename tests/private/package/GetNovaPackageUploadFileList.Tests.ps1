BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageUploadFileList.ps1')

    function Resolve-NovaPackageUploadExplicitFileList {param($ProjectInfo, $PackagePath, $PackageType) return @('explicit')}
    function Resolve-NovaPackageUploadOutputFileList {param($ProjectInfo, $PackageType) return @('output')}
}

Describe 'Get-NovaPackageUploadFileList' {
    It 'returns explicit-resolved list when PackagePath is provided' {
        Get-NovaPackageUploadFileList -ProjectInfo ([pscustomobject]@{}) -PackagePath @('/a') | Should -Be @('explicit')
    }

    It 'returns output-directory list when PackagePath is empty' {
        Get-NovaPackageUploadFileList -ProjectInfo ([pscustomobject]@{}) | Should -Be @('output')
    }

    It 'skips blank PackagePath entries' {
        Get-NovaPackageUploadFileList -ProjectInfo ([pscustomobject]@{}) -PackagePath @('','   ') | Should -Be @('output')
    }
}
