BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/ResolveNovaPackageUploadExplicitFileList.ps1')

    function Get-NovaPackageUploadRequestedTypeList {param($ProjectInfo, $PackageType) return @($PackageType)}
    function Resolve-NovaPackageUploadExplicitFile {param($RequestedPackageTypeList, $PackagePath)
        return [pscustomobject]@{PackagePath=$PackagePath; Type='NuGet'; PackageFileName=[IO.Path]::GetFileName($PackagePath)}
    }
}

Describe 'Resolve-NovaPackageUploadExplicitFileList' {
    It 'resolves each requested file and deduplicates by path' {
        $result = Resolve-NovaPackageUploadExplicitFileList -ProjectInfo ([pscustomobject]@{}) -PackagePath @('/o/a.nupkg','/o/a.nupkg','/o/b.nupkg')
        @($result).Count | Should -Be 2
    }
}
