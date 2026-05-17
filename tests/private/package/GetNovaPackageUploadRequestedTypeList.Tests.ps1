BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))
    . (Join-Path $projectRoot 'src/private/package/GetNovaPackageUploadRequestedTypeList.ps1')

    function Resolve-NovaPackageUploadTypeList {param($ProjectInfo, $PackageType) return @($PackageType | ForEach-Object {"resolved-$_"})}
}

Describe 'Get-NovaPackageUploadRequestedTypeList' {
    It 'returns an empty array when no types are requested' {
        @(Get-NovaPackageUploadRequestedTypeList -ProjectInfo ([pscustomobject]@{}) -PackageType @()).Count | Should -Be 0
    }

    It 'returns the resolved types when requested types are present' {
        Get-NovaPackageUploadRequestedTypeList -ProjectInfo ([pscustomobject]@{}) -PackageType @('NuGet') | Should -Be @('resolved-NuGet')
    }

    It 'skips blank type entries' {
        @(Get-NovaPackageUploadRequestedTypeList -ProjectInfo ([pscustomobject]@{}) -PackageType @('','   ')).Count | Should -Be 0
    }
}
